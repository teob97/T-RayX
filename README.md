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
T-RayX: a Nim library aimed to generate a photorealistic image.

The project has been developed during the course [*Numerical techniques for photorealistic image generation*](https://www.unimi.it/en/education/degree-programme-courses/2022/numerical-tecniques-photorealistic-image-generation) held by Prof. [Maurizio Tomasi][1] at Università degli Studi di Milano (A.Y. 2021/2022)

The main functionality of this library is to generate photorealistic images from input files that describe a scene. (See more details [here](#renderer)).
With T-RayX you are also able to convert PFM files to PNG using the [pfm2png](#pfm2png) command.

## :desktop_computer:  System Requirements
T-RayX works on Windows, Linux and MacOSX machine.

For a proper use of the library you need:
- [Nim](https://nim-lang.org/) version required: 1.6.4
- [Nimble](https://github.com/nim-lang/nimble) package manager
- [simplepng](https://github.com/jrenner/nim-simplepng): use ```nimble install simplepng``` to install it.
- [ffmpeg](https://ffmpeg.org/) and [GNU parallel](https://www.gnu.org/software/parallel/) just for the animations.

## :rocket:  Usage
Run the following commands in the outermost folder of the project.

To generate the executable file, use:

```bash
nimble run
```

To run the tests and check that everything works well, use:
```bash
nimble test
```

Once you have the executable file you are ready to have fun with the following commands.

> ## renderer

Renderer functionality

> ## pfm2png

Convert pfm file in png image using:

```bash
./trayx <file.pfm> <alpha> <gamma> <output.png>
```

It is necessary to set specific values for alpha and gamma parameters.

> ## demo

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
:--:|:--:|:--:|
`alpha = 0.3` | `alpha = 0.6`  |  `alpha = 0.9`


### Example 2

Use the command:

```bash
./trayx demo
```

to create the following animation.

<p align="center"> 
  <img src="output/demo/animation.gif" alt="demo" width="70%" height="70%">
</p>



[1]: https://github.com/ziotom78
