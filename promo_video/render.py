"""Render promo.html to an MP4 (1920x1080, 30fps) with generated music + UI sound effects.

    python render.py              # full video -> pet_scan_ai_promo.mp4
    python render.py --stills 3 11 15 19 22 25 27 33 38 44   # preview frames only
"""
import subprocess, sys, wave, pathlib
import numpy as np
import imageio_ffmpeg
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).parent
FPS = 30
SR = 44100
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


def open_page(p):
    browser = p.chromium.launch(executable_path=CHROME, args=["--force-color-profile=srgb"])
    page = browser.new_page(viewport={"width": 1920, "height": 1080}, device_scale_factor=1)
    page.goto((HERE / "promo.html").as_uri())
    info = page.evaluate("window.READY")
    return browser, page, info


# ---------------------------------------------------------------- audio
def note(freq, dur, kind="pluck", vol=0.2):
    t = np.arange(int(SR * dur)) / SR
    if kind == "pluck":
        env = np.exp(-t * 6)
        w = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(4 * np.pi * freq * t) + 0.1 * np.sin(6 * np.pi * freq * t)
    elif kind == "pad":
        env = np.minimum(1, t / 0.4) * np.minimum(1, (dur - t) / 0.5)
        w = sum(np.sin(2 * np.pi * freq * m * t + m) / m for m in (1, 2, 3)) + 0.5 * np.sin(2 * np.pi * freq * 1.003 * t)
    elif kind == "bass":
        env = np.exp(-t * 3) * np.minimum(1, t / 0.01)
        w = np.sin(2 * np.pi * freq * t) + 0.2 * np.sin(4 * np.pi * freq * t)
    return w * env * vol


def mtof(m):
    return 440 * 2 ** ((m - 69) / 12)


def add(buf, sig, at):
    i = int(at * SR)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


def make_audio(duration, taps, path):
    rng = np.random.default_rng(7)
    buf = np.zeros(int(SR * duration) + SR)
    bpm = 104
    beat = 60 / bpm
    bar = beat * 4
    # C  G  Am F  (uplifting pop progression)
    chords = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]]
    roots = [36, 43, 45, 41]
    nbars = int(duration / bar) + 1
    for b in range(nbars):
        t0 = b * bar
        ch = chords[b % 4]
        for m in ch:
            add(buf, note(mtof(m), bar + 0.3, "pad", 0.035), t0)
        # arpeggio of 8ths
        arp = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 12, ch[0] + 24, ch[2] + 12, ch[1] + 12, ch[2] + 12]
        if t0 > 1.0:
            for i, m in enumerate(arp):
                add(buf, note(mtof(m), 0.6, "pluck", 0.07), t0 + i * beat / 2)
        # bass + drums after the intro
        if t0 >= bar:
            for i in (0, 2.5):
                add(buf, note(mtof(roots[b % 4]), beat * 1.5, "bass", 0.22), t0 + i * beat)
            for i in range(4):
                tk = np.arange(int(SR * 0.25)) / SR
                kick = np.sin(2 * np.pi * (50 + 90 * np.exp(-tk * 30)) * tk) * np.exp(-tk * 12) * 0.35
                if i in (0, 2):
                    add(buf, kick, t0 + i * beat)
                hat = rng.standard_normal(int(SR * 0.05)) * np.exp(-np.arange(int(SR * 0.05)) / SR * 80) * 0.035
                add(buf, np.diff(hat, prepend=0), t0 + i * beat + beat / 2)
                if i in (1, 3):
                    sn = rng.standard_normal(int(SR * 0.15)) * np.exp(-np.arange(int(SR * 0.15)) / SR * 25) * 0.06
                    add(buf, sn, t0 + i * beat)
    # whooshes at scene changes
    for at in (4.9, 9.2, 28.4, 36.4, 41.3):
        n = int(SR * 0.7)
        tt = np.arange(n) / SR
        noise = rng.standard_normal(n)
        # crude sweep: moving-average filter length shrinks over time
        out = np.zeros(n)
        acc = 0.0
        for i in range(n):
            a = 0.02 + 0.5 * (i / n)
            acc += a * (noise[i] - acc)
            out[i] = acc
        env = np.sin(np.pi * tt / 0.7) ** 2
        add(buf, out * env * 0.25, at)
    # soft "pop" on each tap
    for at in taps:
        tt = np.arange(int(SR * 0.09)) / SR
        pop = np.sin(2 * np.pi * (900 - 3000 * tt) * tt) * np.exp(-tt * 45) * 0.18
        add(buf, pop, at)
    # sparkle on the result + CTA
    for at in (23.5, 42.0):
        for i, m in enumerate((84, 88, 91, 96)):
            add(buf, note(mtof(m), 0.5, "pluck", 0.06), at + i * 0.07)

    buf = buf[: int(SR * duration)]
    fade = int(SR * 2.5)
    buf[-fade:] *= np.linspace(1, 0, fade)
    buf[: int(SR * 0.3)] *= np.linspace(0, 1, int(SR * 0.3))
    buf = buf / (np.max(np.abs(buf)) + 1e-9) * 0.85
    pcm = (buf * 32767).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# ---------------------------------------------------------------- video
def render_stills(times):
    out = HERE / "stills"
    out.mkdir(exist_ok=True)
    with sync_playwright() as p:
        browser, page, _ = open_page(p)
        for t in times:
            page.evaluate(f"seek({t})")
            page.screenshot(path=str(out / f"t{t:05.1f}.png"))
        browser.close()


def render_video():
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    with sync_playwright() as p:
        browser, page, info = open_page(p)
        duration, taps = info["duration"], info["taps"]
        wav = HERE / "music.wav"
        make_audio(duration, taps, wav)
        out = HERE / "pet_scan_ai_promo.mp4"
        proc = subprocess.Popen([
            ff, "-y", "-loglevel", "error",
            "-f", "image2pipe", "-framerate", str(FPS), "-c:v", "mjpeg", "-i", "-",
            "-i", str(wav),
            "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-vf", "scale=in_range=pc:out_range=tv,format=yuv420p", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
            "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", str(out),
        ], stdin=subprocess.PIPE)
        total = int(duration * FPS)
        for f in range(total):
            page.evaluate(f"seek({f / FPS})")
            proc.stdin.write(page.screenshot(type="jpeg", quality=95))
            if f % 60 == 0:
                print(f"frame {f}/{total}", flush=True)
        proc.stdin.close()
        proc.wait()
        browser.close()
    print("done ->", out)


if __name__ == "__main__":
    if "--stills" in sys.argv:
        render_stills([float(x) for x in sys.argv[sys.argv.index("--stills") + 1:]])
    else:
        render_video()
