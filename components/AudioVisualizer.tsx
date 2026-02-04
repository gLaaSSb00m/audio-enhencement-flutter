
import React, { useEffect, useRef } from 'react';

interface AudioVisualizerProps {
  isAnimating: boolean;
  color?: string;
  bars?: number;
}

const AudioVisualizer: React.FC<AudioVisualizerProps> = ({ isAnimating, color = '#6366f1', bars = 20 }) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!isAnimating) return;
    
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animationFrame: number;
    const barData = Array.from({ length: bars }, () => Math.random());

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const width = canvas.width;
      const height = canvas.height;
      const barWidth = width / bars;

      ctx.fillStyle = color;

      for (let i = 0; i < bars; i++) {
        // Simple procedural animation for visual feedback
        const target = Math.random() * 0.8 + 0.2;
        barData[i] = barData[i] * 0.8 + target * 0.2;
        
        const h = barData[i] * height;
        const y = (height - h) / 2;
        
        ctx.beginPath();
        ctx.roundRect(i * barWidth + 2, y, barWidth - 4, h, 4);
        ctx.fill();
      }

      animationFrame = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animationFrame);
  }, [isAnimating, color, bars]);

  return (
    <canvas 
      ref={canvasRef} 
      width={400} 
      height={80} 
      className={`w-full h-20 opacity-80 ${!isAnimating && 'grayscale'}`}
    />
  );
};

export default AudioVisualizer;
