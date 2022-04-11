<h1 align="center">
  <br>
  <a href="https://github.com/teob97/T-RayX/"><img src="logo/T-RayX.png" alt="T-RayX" width="300" height="300"></a>
  <br>
  T-RayX
  <br>
</h1>

<h2 align="center">A <a href="https://nim-lang.org/" target="_blank">NIM</a> Raytracing Library.</h2>

<p align="center">
  <a href='https://github.com/teob97/T-RayX/releases'>
  <img src='https://img.shields.io/github/v/release/teob97/T-RayX?color=%23FDD835&label=version&style=for-the-badge'>
  </a>
  <a href='https://github.com/teob97/T-RayX/blob/main/LICENSE'>
  <img src='https://img.shields.io/github/license/teob97/T-RayX?style=for-the-badge'>
  </a>
<!---
  <a href="https://github.com/teob97/T-RayX/releases">
    <img src="https://img.shields.io/github/v/release/teob97/T-RayX?color=orange&&sort=semver&style=flat-square" alt="Version">
  </a>
  <a href="https://github.com/teob97/T-RayX/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/teob97/T-RayX?color=blue&style=flat-square" alt="License">
  </a>
  <a href="https://www.paypal.me/EGatti619">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat-square">
  </a>
-->
</p>

---

## :t-rex:  Overview
T-RayX is a Nim package aimed to generate a photorealistic image.

## :desktop_computer:  System Requirements
T-RayX works on Windows, Linux and MacOSX machine.

Nim version required: 1.6.4

## :rocket:  Example
Convert pfm file in png image using syntax:

```bash
nim r main.nim file.pfm alpha gamma output.png
```

In `src` directory run:

```bash
nim r main.nim ../tests/img/lawn.pbm 0.6 1.45 lawn_a0.6-gamma1.45.png
```

in order to create the following image:

![](output/lawn_a0.6-gamma1.45.png)

It is possible to change the parameters alpha and gamma.
<p float="left">
  <img src="output/lawn_a0.3-gamma1.45.png" width="200" />
  <img src="output/lawn_a0.6-gamma1.45.png" width="200" /> 
  <img src="output/lawn_a0.9-gamma1.45.png" width="200" />
</p>