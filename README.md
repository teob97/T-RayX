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
</p>

---

## :t-rex:  Overview
T-RayX is a Nim package aimed to generate a photorealistic image.

## :desktop_computer:  System Requirements
T-RayX works on Windows, Linux and MacOSX machine.

Nim version required: 1.6.4

## :rocket:  Usage
To generate the executable file, use:

```bash
nimble run
```

### pfm2png

Convert pfm file in png image using:

```bash
./trayx <file.pfm> <alpha> <gamma> <output.png>
```

It is necessary to set specific values for alpha and gamma parameters.

### demo

To run the demo, use:

```bash
./trayx demo [--angle=<angle-deg>] [--output=<output-file>] [--orthogonal]
```
where:
- angle: angle of rotation around z axis. Default 0.
- output: name of output file. Default demo.png.
- orthogonal: flag to chenge camera type. Default perespective.

## 	:sunglasses: Examples

### Example 1

Run:

```bash
./trayx tests/img/lawn.pbm 0.6 1.45 lawn_a0.6-gamma1.45.png
```

in order to create the following image:

<p float="center">
  <img src="output/lawn_a0.6-gamma1.45.png" width="600" />
</p>

It is possible to tune the parameters alpha and gamma.

![](output/lawn_a0.3-gamma1.45.png)  |  ![](output/lawn_a0.6-gamma1.45.png) | ![](output/lawn_a0.9-gamma1.45.png) 
alpha = 0.3 | alpha = 0.6  |  alpha = 0.9


### Example 2

Use the command:

```bash
./trayx demo
```

to create the following animation.

<p align="center"> 
  <img src="output/demo/animation.gif" alt="demo" width="70%" height="70%">
</p>



