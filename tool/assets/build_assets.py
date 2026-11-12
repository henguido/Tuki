"""Genera los recursos PROVISIONALES de TUKI (portada, audio e icono).

Uso (desde la raíz del repo, con pillow, numpy y lameenc instalados):

    python tool/assets/build_assets.py --cover <ilustracion.png> --wav-dir <carpeta con intro_es.wav / intro_en.wav>

- cover.webp: se recodifica la ilustración entregada por el cliente (sin texto).
- intro_es.mp3 / intro_en.mp3: voz sintética SAPI generada con tool/assets/speak.ps1.
- bosque.mp3: ambiente sintetizado aquí mismo (ruido filtrado, gotas y cantos).
- icono: dibujo original generado aquí mismo.
"""

import argparse
import math
import os
import wave

import lameenc
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CHAPTER = os.path.join(ROOT, "assets", "chapters", "bosque-nuboso")
RATE = 44100


def encode_mp3(samples: np.ndarray, path: str, bitrate: int = 96) -> None:
    pcm = np.clip(samples, -1.0, 1.0)
    pcm = (pcm * 32767).astype(np.int16)
    enc = lameenc.Encoder()
    enc.set_bit_rate(bitrate)
    enc.set_in_sample_rate(RATE)
    enc.set_channels(1)
    enc.set_quality(2)
    data = enc.encode(pcm.tobytes()) + enc.flush()
    with open(path, "wb") as f:
        f.write(data)
    print("wrote", os.path.relpath(path, ROOT), len(data), "bytes", round(len(pcm) / RATE, 1), "s")


def narration(wav_path: str, out_path: str) -> None:
    with wave.open(wav_path, "rb") as w:
        assert w.getframerate() == RATE and w.getnchannels() == 1 and w.getsampwidth() == 2
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768
    # Recorta silencios y normaliza.
    loud = np.where(np.abs(pcm) > 0.01)[0]
    pcm = pcm[max(0, loud[0] - RATE // 5): loud[-1] + RATE // 3]
    pcm = pcm / max(1e-6, np.max(np.abs(pcm))) * 0.9
    encode_mp3(pcm, out_path)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / RATE)
    spec *= 1 / (1 + (freqs / cutoff) ** 4)
    return np.fft.irfft(spec, len(x))


def bandpass(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / RATE)
    spec *= (1 / (1 + (freqs / hi) ** 6)) * (1 - 1 / (1 + (freqs / lo) ** 6))
    return np.fft.irfft(spec, len(x))


def ambience(out_path: str, seconds: int = 32) -> None:
    rng = np.random.default_rng(7)
    n = seconds * RATE
    t = np.arange(n) / RATE
    # Los filtros por FFT son circulares: el resultado ya es un bucle continuo.
    wind = lowpass(rng.standard_normal(n), 420)
    wind /= np.max(np.abs(wind))
    swell = 0.55 + 0.45 * np.sin(2 * math.pi * t / seconds * 2 + 1.0) * np.sin(2 * math.pi * t / seconds * 3)
    mix = 0.20 * wind * swell

    drizzle = bandpass(rng.standard_normal(n), 2500, 7000)
    drizzle /= np.max(np.abs(drizzle))
    mix += 0.035 * drizzle

    def add(sig: np.ndarray, start: float) -> None:
        i = int(start * RATE) % n
        idx = (i + np.arange(len(sig))) % n
        mix[idx] += sig

    # Gotas.
    for _ in range(46):
        d = 0.05
        tt = np.arange(int(d * RATE)) / RATE
        f0 = rng.uniform(900, 2200)
        drop = np.sin(2 * math.pi * (f0 + 2500 * tt) * tt) * np.exp(-tt * 70)
        add(drop * rng.uniform(0.03, 0.09), rng.uniform(0, seconds))

    # Cantos de ave: frases de silbidos con barrido de frecuencia.
    def chirp(f_a: float, f_b: float, d: float, vib: float = 0.0) -> np.ndarray:
        tt = np.arange(int(d * RATE)) / RATE
        f = f_a + (f_b - f_a) * (tt / d) + vib * np.sin(2 * math.pi * 28 * tt)
        phase = 2 * math.pi * np.cumsum(f) / RATE
        env = np.sin(math.pi * tt / d) ** 2
        return np.sin(phase) * env

    for start in (2.5, 9.8, 17.0, 24.6):
        base = rng.uniform(2600, 3400)
        for k in range(3):
            add(0.07 * chirp(base, base * 1.35, 0.16), start + k * 0.24)
        add(0.06 * chirp(base * 1.3, base * 0.9, 0.35, 120), start + 0.85)
    for start in (5.6, 13.4, 21.2, 28.3):
        base = rng.uniform(1500, 1900)
        add(0.06 * chirp(base, base * 0.8, 0.5, 40), start)
        add(0.06 * chirp(base * 0.8, base * 1.05, 0.4, 40), start + 0.62)

    # Rana lejana: pulsos graves.
    for start in (7.2, 19.5, 30.0):
        for k in range(4):
            tt = np.arange(int(0.09 * RATE)) / RATE
            croak = np.sin(2 * math.pi * 430 * tt) * np.sign(np.sin(2 * math.pi * 55 * tt)) * np.sin(math.pi * tt / 0.09) ** 2
            add(0.035 * croak, start + k * 0.17)

    mix = mix / np.max(np.abs(mix)) * 0.8
    encode_mp3(mix, out_path, bitrate=112)


def cover(src: str, out_path: str) -> None:
    img = Image.open(src).convert("RGB")
    scale = min(1.0, 1500 / max(img.size))
    if scale < 1.0:
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
    img.save(out_path, "WEBP", quality=84, method=6)
    print("wrote", os.path.relpath(out_path, ROOT), img.size, os.path.getsize(out_path), "bytes")


def icon_image(size: int = 1024) -> Image.Image:
    s = 4  # supermuestreo
    w = size * s
    img = Image.new("RGB", (w, w), "#006C70")
    d = ImageDraw.Draw(img)

    def p(x: float, y: float) -> tuple[float, float]:
        return (x * w, y * w)

    # Sol/niebla.
    d.ellipse([*p(0.16, 0.14), *p(0.84, 0.82)], fill="#D7F8F7")
    # Hoja: dos arcos.
    leaf = []
    for i in range(0, 101):
        a = i / 100
        leaf.append(p(0.20 + 0.60 * a, 0.62 - 0.30 * math.sin(math.pi * a) * (0.6 + 0.4 * a)))
    for i in range(100, -1, -1):
        a = i / 100
        leaf.append(p(0.20 + 0.60 * a, 0.62 + 0.16 * math.sin(math.pi * a)))
    d.polygon(leaf, fill="#7AC943")
    d.line([p(0.20, 0.62), p(0.80, 0.62)], fill="#006C70", width=int(0.022 * w))
    for a in (0.35, 0.5, 0.65):
        d.line([p(a, 0.62), p(a + 0.08, 0.62 - 0.13)], fill="#006C70", width=int(0.016 * w))
        d.line([p(a, 0.62), p(a + 0.07, 0.62 + 0.08)], fill="#006C70", width=int(0.016 * w))
    # Gota naranja.
    d.ellipse([*p(0.62, 0.20), *p(0.76, 0.34)], fill="#E64E24")
    return img.resize((size, size), Image.LANCZOS)


def icons() -> None:
    base = icon_image()
    res = os.path.join(ROOT, "android", "app", "src", "main", "res")
    for name, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
        path = os.path.join(res, f"mipmap-{name}", "ic_launcher.png")
        base.resize((px, px), Image.LANCZOS).save(path)
    ios = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.isdir(ios):
        for f in os.listdir(ios):
            if f.endswith(".png"):
                with Image.open(os.path.join(ios, f)) as old:
                    px = old.size[0]
                base.resize((px, px), Image.LANCZOS).save(os.path.join(ios, f))
    os.makedirs(os.path.join(ROOT, "assets", "brand"), exist_ok=True)
    base.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, "assets", "brand", "icon.png"))
    print("wrote icons")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--cover")
    ap.add_argument("--wav-dir")
    args = ap.parse_args()
    os.makedirs(os.path.join(CHAPTER, "audio"), exist_ok=True)
    if args.cover:
        cover(args.cover, os.path.join(CHAPTER, "cover.webp"))
    if args.wav_dir:
        narration(os.path.join(args.wav_dir, "intro_es.wav"), os.path.join(CHAPTER, "audio", "intro_es.mp3"))
        narration(os.path.join(args.wav_dir, "intro_en.wav"), os.path.join(CHAPTER, "audio", "intro_en.mp3"))
    ambience(os.path.join(CHAPTER, "audio", "bosque.mp3"))
    icons()
