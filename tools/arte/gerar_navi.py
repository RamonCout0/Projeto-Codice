#!/usr/bin/env python3
"""Gera a NAVI vetorial do Codice: um SVG por humor, com cores-coringa.

As cores #FF0001..#FF0006 nao sao cores de verdade: o app troca cada uma pela
cor do elemento do NAVI na hora de desenhar (ColorMapper do flutter_svg).
  #FF0001 corpo        #FF0002 corpo escuro   #FF0003 brilho
  #FF0004 placa do rosto (escura)             #FF0005 olhos/luz
  #FF0006 placa do rosto (um tom acima)
"""
import os
import sys

DESTINO = sys.argv[1] if len(sys.argv) > 1 else 'assets/arte'
os.makedirs(DESTINO, exist_ok=True)

C1, C2, C3, C4, C5, C6 = ('#FF0001', '#FF0002', '#FF0003', '#FF0004', '#FF0005', '#FF0006')

DEFS = f'''<defs>
  <linearGradient id="corpo" x1="0.1" y1="0" x2="0.9" y2="1">
    <stop offset="0" stop-color="{C3}"/><stop offset="0.38" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>
  </linearGradient>
  <linearGradient id="membro" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>
  </linearGradient>
  <linearGradient id="placa" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{C6}"/><stop offset="1" stop-color="{C4}"/>
  </linearGradient>
  <radialGradient id="aura" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{C1}" stop-opacity="0.34"/><stop offset="1" stop-color="{C1}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="luz" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{C5}" stop-opacity="0.55"/><stop offset="1" stop-color="{C5}" stop-opacity="0"/>
  </radialGradient>
</defs>'''


def olho(x, y, r=9, brilho=True, dx=0, dy=0):
    s = f'<circle cx="{x}" cy="{y}" r="{r + 5}" fill="url(#luz)"/><circle cx="{x}" cy="{y}" r="{r}" fill="{C5}"/>'
    if brilho:
        s += f'<circle cx="{x - r * 0.32 + dx}" cy="{y - r * 0.34 + dy}" r="{r * 0.3}" fill="#FFFFFF" opacity="0.92"/>'
    return s


def traco(d, w=4):
    return f'<path d="{d}" fill="none" stroke="{C5}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


ROSTOS = {
    'esperando': olho(78, 90) + olho(122, 90) + traco('M91 108 Q100 114 109 108', 3.6),
    'lendo': (f'<circle cx="78" cy="92" r="14" fill="url(#luz)"/><path d="M69 90 H87 a9 9 0 0 1 -18 0 z" fill="{C5}"/>'
              f'<circle cx="122" cy="92" r="14" fill="url(#luz)"/><path d="M113 90 H131 a9 9 0 0 1 -18 0 z" fill="{C5}"/>'
              + traco('M69 87 H87 M113 87 H131', 3) + traco('M94 110 H106', 3.4)),
    'curiosa': (olho(78, 91, 10.5) + olho(122, 91, 10.5) + traco('M64 72 Q76 63 90 69', 3.4)
                + traco('M112 72 H130', 3.4)
                + f'<circle cx="100" cy="110" r="4.6" fill="none" stroke="{C5}" stroke-width="3.4"/>'),
    'feliz': (traco('M67 93 Q78 78 89 93', 4.8) + traco('M111 93 Q122 78 133 93', 4.8)
              + f'<path d="M86 103 Q100 124 114 103 Z" fill="{C5}"/>'
              + f'<path d="M93 111 Q100 118 107 111 Q100 115 93 111z" fill="{C4}" opacity="0.55"/>'),
    'confusa': (olho(78, 91, 8.5) + traco('M113 84 L129 99 M129 84 L113 99', 4.2)
                + traco('M88 111 q4.5 -6 9 0 t9 0 t9 0', 3.4)),
    'pensando': (olho(82, 88, 8.5, dx=2, dy=-1) + olho(126, 88, 8.5, dx=2, dy=-1) + traco('M93 109 L109 106', 3.6)
                 + f'<circle cx="156" cy="40" r="3.6" fill="{C5}" opacity="0.85"/>'
                 + f'<circle cx="168" cy="26" r="5.4" fill="{C5}" opacity="0.85"/>'
                 + f'<circle cx="184" cy="9" r="7.4" fill="{C5}" opacity="0.85"/>'),
}


def navi(humor):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 240" width="200" height="240">
{DEFS}
<circle cx="100" cy="128" r="100" fill="url(#aura)"/>
<ellipse cx="100" cy="226" rx="46" ry="8" fill="#000" opacity="0.28"/>
<!-- pernas -->
<rect x="76" y="196" width="20" height="26" rx="10" fill="url(#membro)"/>
<rect x="104" y="196" width="20" height="26" rx="10" fill="url(#membro)"/>
<!-- bracos -->
<rect x="38" y="146" width="20" height="44" rx="10" fill="url(#membro)" transform="rotate(16 48 146)"/>
<rect x="142" y="146" width="20" height="44" rx="10" fill="url(#membro)" transform="rotate(-16 152 146)"/>
<!-- corpo -->
<rect x="60" y="128" width="80" height="78" rx="34" fill="url(#corpo)"/>
<circle cx="100" cy="168" r="12" fill="{C4}"/>
<circle cx="100" cy="168" r="12" fill="none" stroke="{C3}" stroke-opacity="0.6" stroke-width="2"/>
<circle cx="100" cy="168" r="5" fill="{C5}"/>
<!-- orelhas -->
<rect x="18" y="72" width="18" height="42" rx="9" fill="{C2}"/>
<rect x="164" y="72" width="18" height="42" rx="9" fill="{C2}"/>
<rect x="24" y="84" width="6" height="18" rx="3" fill="{C5}"/>
<rect x="170" y="84" width="6" height="18" rx="3" fill="{C5}"/>
<!-- antena -->
<path d="M100 40 V22" stroke="{C2}" stroke-width="5" stroke-linecap="round"/>
<circle cx="100" cy="14" r="15" fill="url(#luz)"/>
<circle cx="100" cy="14" r="7.5" fill="{C5}"/>
<circle cx="97.6" cy="11.4" r="2.4" fill="#FFFFFF" opacity="0.9"/>
<!-- cabeca -->
<rect x="30" y="36" width="140" height="110" rx="50" fill="url(#corpo)"/>
<path d="M50 68 Q56 50 82 45" fill="none" stroke="{C3}" stroke-width="5.5" stroke-linecap="round" opacity="0.65"/>
<!-- placa do rosto -->
<rect x="44" y="58" width="112" height="68" rx="32" fill="url(#placa)"/>
<rect x="44" y="58" width="112" height="68" rx="32" fill="none" stroke="{C1}" stroke-opacity="0.4" stroke-width="1.6"/>
<circle cx="62" cy="109" r="6.5" fill="{C1}" opacity="0.32"/>
<circle cx="138" cy="109" r="6.5" fill="{C1}" opacity="0.32"/>
{ROSTOS[humor]}
</svg>
'''


for h in ROSTOS:
    with open(os.path.join(DESTINO, f'navi_{h}.svg'), 'w') as f:
        f.write(navi(h))
print(len(ROSTOS), 'expressoes em', DESTINO)
