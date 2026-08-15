#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
frames="$repo_root/outputs/demo-video"
public_dir="$repo_root/apps/web/public/demo"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

video_only="$work_dir/heirloom-video.mp4"
audio_only="$work_dir/heirloom-audio.m4a"
output="$frames/Heirloom_One_Minute_Demo.mp4"

(command -v say >/dev/null && say -v Samantha -r 165 -f "$frames/narration.txt" -o "$frames/narration.aiff") || {
  printf 'macOS say is required to regenerate the narration track.\n' >&2
  exit 1
}

(cd "$repo_root/apps/web" && node scripts/render-demo-frames.mjs)

ffmpeg -y \
  -loop 1 -t 8  -i "$frames/rendered/01-intro.png" \
  -loop 1 -t 9  -i "$frames/rendered/02-owner-control.png" \
  -loop 1 -t 12 -i "$frames/rendered/03-funded-vault.png" \
  -loop 1 -t 11 -i "$frames/rendered/04-liveness.png" \
  -loop 1 -t 9  -i "$frames/rendered/05-destination-lock.png" \
  -loop 1 -t 8  -i "$frames/rendered/06-evidence.png" \
  -loop 1 -t 3  -i "$frames/rendered/07-outro.png" \
  -filter_complex "
    [0:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=7.5:d=0.5[v0];
    [1:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=8.5:d=0.5[v1];
    [2:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=11.5:d=0.5[v2];
    [3:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=10.5:d=0.5[v3];
    [4:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=8.5:d=0.5[v4];
    [5:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=7.5:d=0.5[v5];
    [6:v]setsar=1,fade=t=in:st=0:d=0.5,fade=t=out:st=2.5:d=0.5[v6];
    [v0][v1][v2][v3][v4][v5][v6]concat=n=7:v=1:a=0,format=yuv420p[v]
  " \
  -map "[v]" -r 30 -c:v libx264 -preset medium -crf 21 -movflags +faststart "$video_only"

ffmpeg -y -i "$frames/narration.aiff" \
  -af "atempo=1.059,loudnorm=I=-16:LRA=7:TP=-1.5,apad,atrim=0:60" \
  -c:a aac -b:a 160k "$audio_only"

ffmpeg -y -i "$video_only" -i "$audio_only" \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy -t 60 -movflags +faststart "$output"

mkdir -p "$public_dir"
cp "$output" "$public_dir/heirloom-one-minute-demo.mp4"
ffmpeg -y -i "$output" -vn -c:a aac -b:a 160k "$public_dir/heirloom-demo-narration.m4a"
mkdir -p "$public_dir/scenes"
cp "$frames/01-overview.png" "$public_dir/scenes/overview.png"
cp "$frames/06-vault-tokens.png" "$public_dir/scenes/funded-vault.png"
cp "$frames/04-activity.png" "$public_dir/scenes/activity.png"
cp "$frames/02-beneficiaries.png" "$public_dir/scenes/beneficiaries.png"
cp "$frames/03-security.png" "$public_dir/scenes/security.png"
cp "$frames/05-blockscout.png" "$public_dir/scenes/blockscout.png"

printf 'Created %s\n' "$output"
shasum -a 256 "$output"
ffprobe -v error -show_entries format=duration,size -of default=nw=1 "$output"
