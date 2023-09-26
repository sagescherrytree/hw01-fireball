import { vec3, vec4, mat4 } from 'gl-matrix';
import Drawable from './Drawable';
import { gl } from '../../globals';

var activeProgram: WebGLProgram = null;

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrCol: number;

  unifWorldOrigin: WebGLUniformLocation;
  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifColor: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;
  unifCamPos: WebGLUniformLocation;
  unifFreq: WebGLUniformLocation;
  unifAmp: WebGLUniformLocation;
  unifGlow: WebGLUniformLocation;
  unifAmbient: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrCol = gl.getAttribLocation(this.prog, "vs_Col");
    this.unifModel = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewProj = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifColor = gl.getUniformLocation(this.prog, "u_Color");
    this.unifTime = gl.getUniformLocation(this.prog, "u_Time");
    this.unifCamPos = gl.getUniformLocation(this.prog, "u_CamPos");
    this.unifWorldOrigin = gl.getUniformLocation(this.prog, "U_WorldOrigin");
    this.unifFreq = gl.getUniformLocation(this.prog, "u_Frequency");
    this.unifAmp = gl.getUniformLocation(this.prog, "u_Amplitude");
    this.unifGlow = gl.getUniformLocation(this.prog, "u_Glow");
    this.unifAmbient = gl.getUniformLocation(this.prog, "u_Ambient");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setGeometryColor(color: vec4) {
    this.use();
    if (this.unifColor !== -1) {
      gl.uniform4fv(this.unifColor, color);
    }
  }

  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, time);
    }
  }

  setCamPos(camPos: vec3) {
    this.use();
    if (this.unifCamPos !== -1) {
      gl.uniform3f(this.unifCamPos, camPos[0], camPos[1], camPos[2]);
    }
  }

  setWorldOrigin(worldOrigin: vec3) {
    this.use();
    if (this.unifWorldOrigin !== -1) {
      gl.uniform4fv(this.unifWorldOrigin, vec4.fromValues(worldOrigin[0], worldOrigin[1], worldOrigin[2], 1))
    }
  }

  setFrequency(frequency: number) {
    this.use();
    if (this.unifFreq !== -1) {
      gl.uniform1f(this.unifFreq, frequency);
    }
  }

  setAmplitude(amplitude: number) {
    this.use();
    if (this.unifAmp !== -1) {
      gl.uniform1f(this.unifAmp, amplitude);
    }
  }

  setGlow(glow: number) {
    this.use();
    if (this.unifGlow !== -1) {
      gl.uniform1f(this.unifGlow, glow);
    }
  }

  setAmbient(ambient: number) {
    this.use();
    if (this.unifAmbient !== -1) {
      gl.uniform1f(this.unifAmbient, ambient);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrCol != -1 && d.bindCol()) {
      gl.enableVertexAttribArray(this.attrCol);
      gl.vertexAttribPointer(this.attrCol, 4, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
    if (this.attrCol != -1) gl.disableVertexAttribArray(this.attrCol);
  }
};

export default ShaderProgram;
