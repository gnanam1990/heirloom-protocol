#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import {
  cpSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

import { mutations } from "../mutations/manifest.mjs";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const repository = resolve(scriptDirectory, "..");
const ignoredNames = new Set([
  ".git",
  ".next",
  ".wrangler",
  "broadcast",
  "cache",
  "dist",
  "node_modules",
  "out",
]);

function usage() {
  process.stdout.write(
    "Usage: ./script/check-invariant-mutations.mjs [--all | --id I1[,I2...]]\n",
  );
}

function selectedMutations() {
  const args = process.argv.slice(2);
  if (args.length === 0 || (args.length === 1 && args[0] === "--all")) {
    return mutations;
  }
  if (args.length === 2 && args[0] === "--id") {
    const requested = new Set(args[1].split(",").map((value) => value.toUpperCase()));
    const selected = mutations.filter((mutation) => requested.has(mutation.id));
    const missing = [...requested].filter(
      (id) => !mutations.some((mutation) => mutation.id === id),
    );
    if (missing.length > 0) {
      throw new Error(`Unknown mutation id: ${missing.join(", ")}`);
    }
    return selected;
  }
  usage();
  process.exit(2);
}

function copyRepository(destination) {
  cpSync(repository, destination, {
    recursive: true,
    filter(source) {
      const pathFromRoot = relative(repository, source);
      if (pathFromRoot === "") return true;
      return !pathFromRoot.split(sep).some((part) => ignoredNames.has(part));
    },
  });
}

function run(command, args, cwd) {
  return spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    env: { ...process.env, FOUNDRY_PROFILE: "default" },
    maxBuffer: 20 * 1024 * 1024,
  });
}

function outputOf(result) {
  return `${result.stdout ?? ""}${result.stderr ?? ""}`;
}

function replaceExactlyOnce(source, find, replacement, id) {
  const first = source.indexOf(find);
  const second = first === -1 ? -1 : source.indexOf(find, first + find.length);
  if (first === -1 || second !== -1) {
    throw new Error(
      `${id}: mutation anchor must occur exactly once; first=${first}, second=${second}`,
    );
  }
  return `${source.slice(0, first)}${replacement}${source.slice(first + find.length)}`;
}

const selected = selectedMutations();
const temporaryRoot = mkdtempSync(join(tmpdir(), "heirloom-mutations-"));
const temporaryRepository = join(temporaryRoot, basename(repository));
let killed = 0;
let failed = false;

try {
  copyRepository(temporaryRepository);

  for (const mutation of selected) {
    const target = join(temporaryRepository, mutation.file);
    const original = readFileSync(target, "utf8");
    const mutated = replaceExactlyOnce(
      original,
      mutation.find,
      mutation.replace,
      mutation.id,
    );
    writeFileSync(target, mutated);

    const build = run("forge", ["build"], temporaryRepository);
    if (build.status !== 0) {
      failed = true;
      process.stderr.write(`[INVALID] ${mutation.id} ${mutation.title}\n`);
      process.stderr.write(outputOf(build));
      writeFileSync(target, original);
      continue;
    }

    const test = run(
      "forge",
      [
        "test",
        "--match-contract",
        "HeirloomInvariantMatrixTest",
        "--match-test",
        mutation.test,
        "-vv",
      ],
      temporaryRepository,
    );
    const testOutput = outputOf(test);
    if (test.status !== 0 && testOutput.includes("[FAIL") && testOutput.includes(mutation.test)) {
      killed += 1;
      process.stdout.write(`[KILLED] ${mutation.id} ${mutation.title}\n`);
    } else if (test.status === 0) {
      failed = true;
      process.stderr.write(`[SURVIVED] ${mutation.id} ${mutation.title}\n`);
    } else {
      failed = true;
      process.stderr.write(`[HARNESS ERROR] ${mutation.id} ${mutation.title}\n`);
      process.stderr.write(testOutput);
    }

    writeFileSync(target, original);
  }
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true });
}

process.stdout.write(`Mutation score: ${killed}/${selected.length} killed\n`);
if (failed || killed !== selected.length) process.exit(1);
