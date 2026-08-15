"use client";

import { Pause, Play, RotateCcw, Type } from "lucide-react";
import Image from "next/image";
import { type CSSProperties, useEffect, useMemo, useRef, useState } from "react";

const TOTAL_DURATION = 60;

const scenes = [
  {
    start: 0,
    end: 8,
    kicker: "The problem",
    title: "Self-custody needs a continuity plan.",
    body: "Heirloom turns prolonged owner inactivity into a precommitted USDC distribution on Base.",
    image: "/demo/scenes/overview.png",
    alt: "Heirloom owner dashboard overview",
    stat: "Non-custodial",
    statLabel: "Owner remains in control",
  },
  {
    start: 8,
    end: 17,
    kicker: "Owner control",
    title: "Wallet or passkey. No seed phrase sharing.",
    body: "Only fresh authorization attributable to the current owner can extend the liveness clock.",
    image: "/demo/scenes/overview.png",
    alt: "Heirloom wallet connection and owner controls",
    stat: "90 days",
    statLabel: "Minimum inactivity period",
  },
  {
    start: 17,
    end: 29,
    kicker: "Verified test vault",
    title: "Twenty USDC, visible on Base Sepolia.",
    body: "The funded vault, official USDC asset, implementation, and public state can be independently inspected.",
    image: "/demo/scenes/funded-vault.png",
    alt: "Blockscout showing twenty USDC in the funded Heirloom vault",
    stat: "20 USDC",
    statLabel: "Funded public test vault",
  },
  {
    start: 29,
    end: 40,
    kicker: "Liveness sequence",
    title: "Inactivity first. Challenge second.",
    body: "A claim request moves no funds. Fresh owner activity can cancel it before distribution becomes irreversible.",
    image: "/demo/scenes/activity.png",
    alt: "Heirloom activity and lifecycle evidence view",
    stat: "7 days",
    statLabel: "Owner challenge window",
  },
  {
    start: 40,
    end: 49,
    kicker: "Destination lock",
    title: "The executor cannot aim the payout.",
    body: "The contract derives the recipient, amount, and exactly one valid destination phase from committed rules and time.",
    image: "/demo/scenes/beneficiaries.png",
    alt: "Heirloom destination-locked beneficiary schedule",
    stat: "1 route",
    statLabel: "Valid in each time phase",
  },
  {
    start: 49,
    end: 57,
    kicker: "Engineering evidence",
    title: "Security claims backed by executable checks.",
    body: "The release candidate includes deterministic, fuzz, stateful, mutation, and Base USDC fork evidence.",
    image: "/demo/scenes/security.png",
    alt: "Heirloom security and recovery controls",
    stat: "73 tests",
    statLabel: "Plus 16 of 16 mutants killed",
  },
  {
    start: 57,
    end: 60,
    kicker: "Built for Base",
    title: "Permissionless execution without payout authority.",
    body: "A proposal prototype for long-duration self-custody continuity—not a public mainnet product.",
    image: "/demo/scenes/blockscout.png",
    alt: "Public Heirloom contract proof on Base Sepolia Blockscout",
    stat: "Base Sepolia",
    statLabel: "Public, verifiable prototype",
  },
] as const;

function timeLabel(value: number) {
  const seconds = Math.max(0, Math.min(TOTAL_DURATION, Math.floor(value)));
  return `0:${seconds.toString().padStart(2, "0")}`;
}

export function AnimatedDemo() {
  const frameRef = useRef<number | null>(null);
  const startRef = useRef<number | null>(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [playing, setPlaying] = useState(false);

  const activeIndex = useMemo(() => {
    const index = scenes.findIndex(
      (scene) => currentTime >= scene.start && currentTime < scene.end,
    );
    return index === -1 ? scenes.length - 1 : index;
  }, [currentTime]);
  const scene = scenes[activeIndex];
  const sceneProgress = Math.min(
    1,
    Math.max(0, (currentTime - scene.start) / (scene.end - scene.start)),
  );

  useEffect(() => {
    if (!playing) return;
    const sync = (now: number) => {
      startRef.current ??= now;
      const next = (now - startRef.current) / 1000;
      if (next >= TOTAL_DURATION) {
        setCurrentTime(TOTAL_DURATION);
        setPlaying(false);
        startRef.current = null;
        return;
      }
      setCurrentTime(next);
      frameRef.current = requestAnimationFrame(sync);
    };
    frameRef.current = requestAnimationFrame(sync);
    return () => {
      if (frameRef.current !== null) cancelAnimationFrame(frameRef.current);
    };
  }, [playing]);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const autoplayFrame = requestAnimationFrame((now) => {
      startRef.current = now;
      setPlaying(true);
    });
    return () => cancelAnimationFrame(autoplayFrame);
  }, []);

  function togglePlayback() {
    if (playing) {
      setPlaying(false);
      startRef.current = null;
    } else {
      const next = currentTime >= TOTAL_DURATION ? 0 : currentTime;
      setCurrentTime(next);
      startRef.current = performance.now() - next * 1000;
      setPlaying(true);
    }
  }

  function seek(value: number) {
    const next = Math.max(0, Math.min(TOTAL_DURATION, value));
    setCurrentTime(next);
    if (playing) startRef.current = performance.now() - next * 1000;
  }

  function restart() {
    setCurrentTime(0);
    startRef.current = performance.now();
    setPlaying(true);
  }

  const stageStyle = {
    "--scene-progress": sceneProgress.toString(),
  } as CSSProperties;

  return (
    <section className="html-demo" aria-label="Interactive Heirloom product walkthrough">
      <div className="html-demo-stage" style={stageStyle}>
        <div className="demo-ambient demo-ambient-one" />
        <div className="demo-ambient demo-ambient-two" />

        <div className="html-demo-copy" key={`copy-${activeIndex}`} aria-live="polite">
          <div className="html-demo-step">
            <span>{String(activeIndex + 1).padStart(2, "0")}</span>
            <span>{scene.kicker}</span>
          </div>
          <h2>{scene.title}</h2>
          <p>{scene.body}</p>
          <div className="html-demo-stat">
            <strong>{scene.stat}</strong>
            <span>{scene.statLabel}</span>
          </div>
        </div>

        <div className="html-demo-browser" key={`image-${activeIndex}`}>
          <div className="html-demo-browser-bar">
            <span />
            <span />
            <span />
            <div>heirloom-protocol-production.up.railway.app</div>
          </div>
          <div className="html-demo-image-wrap">
            <Image
              src={scene.image}
              alt={scene.alt}
              width={1185}
              height={833}
              sizes="(max-width: 760px) 100vw, 58vw"
            />
            <div className="html-demo-scan" />
          </div>
        </div>

        <div className="html-demo-caption" aria-live="polite">
          {scene.body}
        </div>
      </div>

      <div className="html-demo-controls">
        <button className="html-demo-play" type="button" onClick={togglePlayback}>
          {playing ? <Pause size={19} /> : <Play size={19} fill="currentColor" />}
          <span>{playing ? "Pause" : currentTime > 0 ? "Continue" : "Play demo"}</span>
        </button>
        <button className="html-demo-icon-button" type="button" onClick={restart} aria-label="Restart demo">
          <RotateCcw size={17} />
        </button>
        <span className="html-demo-time">{timeLabel(currentTime)}</span>
        <input
          className="html-demo-progress"
          aria-label="Demo progress"
          type="range"
          min="0"
          max={TOTAL_DURATION}
          step="0.1"
          value={currentTime}
          onChange={(event) => seek(Number(event.currentTarget.value))}
        />
        <span className="html-demo-time">1:00</span>
        <span className="html-demo-text-mode">
          <Type size={16} aria-hidden="true" /> Text only
        </span>
      </div>

      <div className="html-demo-chapters" aria-label="Demo chapters">
        {scenes.map((item, index) => (
          <button
            key={item.kicker}
            type="button"
            className={index === activeIndex ? "html-demo-chapter-active" : ""}
            onClick={() => seek(item.start)}
          >
            <span>{String(index + 1).padStart(2, "0")}</span>
            {item.kicker}
          </button>
        ))}
      </div>
    </section>
  );
}
