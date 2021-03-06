class AudioReactiveShader extends AbstractShaderAnimation{
  private int[] freqs;
    AudioReactiveShader(String shaderFile){
      super(shaderFile);
    }
    /**
     *  an array of bands to analyse and pass to the shader
     **/
    AudioReactiveShader(String shaderFile, int[] freqs){
      super(shaderFile);
      this.freqs = freqs;
    }

    protected void setAdditionalParams(FFT fft){
      for(int i = 0; i < freqs.length; i++){
        String paramName = "freq"+i;

        shader.set(paramName, fft.spectrum[freqs[i]]*30);
      }
    }

}
