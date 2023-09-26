import { vec4, vec3 } from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import { setGL } from './globals';
import ShaderProgram, { Shader } from './rendering/gl/ShaderProgram';
import Drawable from './rendering/gl/Drawable';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  colour: [255, 193, 0, 1],
  frequency: 1.0,
  amplitude: 5.0,
  glow: 6.0,
  ambient: 0.7,
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset Scene': resetScene
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let time: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function resetScene() {
  controls.tesselations = 5;
  controls.frequency = 1.0;
  controls.amplitude = 5.0;
  controls.glow = 6.0;
  controls.ambient = 0.7;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset Scene');
  gui.addColor(controls, 'colour');
  gui.add(controls, 'frequency', 0.0, 4.0).step(0.2);
  gui.add(controls, 'amplitude', 0.0, 10.0).step(0.2);
  gui.add(controls, 'glow', 1.0, 10.0).step(0.5);
  gui.add(controls, 'ambient', 0.0, 1.0).step(0.05);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement>document.getElementById('canvas');
  const gl = <WebGL2RenderingContext>canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // New shader.
  const noiseModifier = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl'))
  ]);

  const backgroundModifier = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl'))
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);

    let worldOrigin: vec3 = vec3.fromValues(0, 0, 0);

    renderer.clear();
    if (controls.tesselations != prevTesselations) {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    // Toggles
    noiseModifier.setFrequency(controls.frequency);
    noiseModifier.setAmplitude(controls.amplitude);
    noiseModifier.setGlow(controls.glow);
    noiseModifier.setAmbient(controls.ambient);

    let baseColour = vec4.fromValues(controls.colour[0] / 255, controls.colour[1] / 255, controls.colour[2] / 255, controls.colour[3] / 255);

    noiseModifier.setGeometryColor(baseColour);
    backgroundModifier.setGeometryColor(baseColour);

    // Render noise shader.
    renderer.render(camera, backgroundModifier, [icosphere], vec4.fromValues(255 / 255, 193 / 255, 0, 1), time, worldOrigin);
    renderer.render(camera, noiseModifier, [icosphere], baseColour, time, worldOrigin);
    stats.end();
    time++;

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function () {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
