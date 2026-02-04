
import React, { useState, useRef, useEffect } from 'react';
import AudioVisualizer from './AudioVisualizer';

interface AudioPlayerProps {
  url: string;
  title: string;
  accentColor?: string;
}

const AudioPlayer: React.FC<AudioPlayerProps> = ({ url, title, accentColor = 'indigo' }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const audioRef = useRef<HTMLAudioElement>(null);

  const togglePlay = () => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.pause();
      } else {
        audioRef.current.play();
      }
      setIsPlaying(!isPlaying);
    }
  };

  useEffect(() => {
    const audio = audioRef.current;
    if (audio) {
      const handleEnded = () => setIsPlaying(false);
      audio.addEventListener('ended', handleEnded);
      return () => audio.removeEventListener('ended', handleEnded);
    }
  }, []);

  return (
    <div className={`p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl transition-all hover:border-${accentColor}-500/50`}>
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-400">{title}</h3>
        <a 
          href={url} 
          download={`${title.toLowerCase().replace(/\s/g, '_')}.wav`}
          className="text-slate-500 hover:text-white transition-colors"
          title="Download Audio"
        >
          <i className="fa-solid fa-download"></i>
        </a>
      </div>
      
      <div className="mb-4">
        <AudioVisualizer isAnimating={isPlaying} color={accentColor === 'indigo' ? '#6366f1' : '#10b981'} />
      </div>

      <div className="flex items-center gap-4">
        <button 
          onClick={togglePlay}
          className={`w-12 h-12 flex items-center justify-center rounded-full bg-${accentColor}-600 hover:bg-${accentColor}-500 transition-all shadow-lg shadow-${accentColor}-500/20`}
        >
          <i className={`fa-solid ${isPlaying ? 'fa-pause' : 'fa-play'} text-white text-lg`}></i>
        </button>
        <div className="flex-1">
          <audio ref={audioRef} src={url} className="hidden" />
          <div className="h-1 bg-slate-800 rounded-full overflow-hidden">
            <div 
              className={`h-full bg-${accentColor}-500 transition-all duration-300`} 
              style={{ width: isPlaying ? '100%' : '0%', transitionDuration: isPlaying ? '30s' : '0.5s' }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default AudioPlayer;
