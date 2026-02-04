
import React, { useState, useRef, useCallback } from 'react';
import { AppStatus, AudioState, EnhancementResult } from './types';
import { enhanceAudio, getGeminiInsights } from './services/audioService';
import AudioPlayer from './components/AudioPlayer';

const App: React.FC = () => {
  const [result, setResult] = useState<EnhancementResult>({
    original: { blob: null, url: null, name: '' },
    enhanced: null,
    status: AppStatus.IDLE
  });
  const [insights, setInsights] = useState<string>('');
  const [isRecording, setIsRecording] = useState(false);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const url = URL.createObjectURL(file);
    setResult({
      original: { blob: file, url, name: file.name },
      enhanced: null,
      status: AppStatus.IDLE
    });
    setInsights('');
  };

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream);
      mediaRecorderRef.current = recorder;
      audioChunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) audioChunksRef.current.push(e.data);
      };

      recorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' });
        const url = URL.createObjectURL(audioBlob);
        setResult({
          original: { blob: audioBlob, url, name: 'Recorded Audio' },
          enhanced: null,
          status: AppStatus.IDLE
        });
        setInsights('');
      };

      recorder.start();
      setIsRecording(true);
    } catch (err) {
      console.error("Recording error:", err);
      alert("Please allow microphone access to record audio.");
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());
    }
  };

  const handleEnhance = async () => {
    if (!result.original.blob) return;

    setResult(prev => ({ ...prev, status: AppStatus.PROCESSING }));
    
    try {
      // Run enhancement and Gemini insights concurrently
      const [enhancedBlob, aiInsights] = await Promise.all([
        enhanceAudio(result.original.blob),
        getGeminiInsights(result.original.blob)
      ]);

      const enhancedUrl = URL.createObjectURL(enhancedBlob);
      
      setInsights(aiInsights);
      setResult(prev => ({
        ...prev,
        enhanced: { blob: enhancedBlob, url: enhancedUrl, name: 'Enhanced Audio' },
        status: AppStatus.COMPLETED
      }));
    } catch (error: any) {
      setResult(prev => ({
        ...prev,
        status: AppStatus.ERROR,
        error: error.message || "Failed to enhance audio. Ensure your local API at http://127.0.0.1:7860 is running."
      }));
    }
  };

  const reset = () => {
    setResult({
      original: { blob: null, url: null, name: '' },
      enhanced: null,
      status: AppStatus.IDLE
    });
    setInsights('');
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-12">
      {/* Header */}
      <header className="text-center mb-16 space-y-4">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-indigo-600/10 text-indigo-400 mb-4 border border-indigo-500/20">
          <i className="fa-solid fa-wand-magic-sparkles text-2xl"></i>
        </div>
        <h1 className="text-5xl font-black bg-gradient-to-r from-white via-indigo-200 to-indigo-400 bg-clip-text text-transparent">
          CrystalClear AI
        </h1>
        <p className="text-slate-400 text-lg max-w-xl mx-auto">
          Professional-grade audio enhancement. Remove noise, clarify speech, and get AI-driven insights in seconds.
        </p>
      </header>

      <main className="space-y-8">
        {/* Input Controls */}
        {!result.original.blob && !isRecording && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <label className="group relative overflow-hidden p-8 rounded-3xl bg-slate-900/50 border-2 border-dashed border-slate-800 hover:border-indigo-500/50 transition-all cursor-pointer flex flex-col items-center text-center">
              <input type="file" accept="audio/*" onChange={handleFileUpload} className="hidden" />
              <div className="w-14 h-14 rounded-full bg-slate-800 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <i className="fa-solid fa-cloud-arrow-up text-xl text-indigo-400"></i>
              </div>
              <span className="text-lg font-bold text-slate-200">Upload Audio File</span>
              <span className="text-sm text-slate-500 mt-1">MP3, WAV, M4A up to 50MB</span>
            </label>

            <button 
              onClick={startRecording}
              className="group relative overflow-hidden p-8 rounded-3xl bg-slate-900/50 border-2 border-dashed border-slate-800 hover:border-rose-500/50 transition-all flex flex-col items-center text-center"
            >
              <div className="w-14 h-14 rounded-full bg-slate-800 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                <i className="fa-solid fa-microphone text-xl text-rose-400"></i>
              </div>
              <span className="text-lg font-bold text-slate-200">Record From Mic</span>
              <span className="text-sm text-slate-500 mt-1">Capture live speech instantly</span>
            </button>
          </div>
        )}

        {/* Active Recording State */}
        {isRecording && (
          <div className="p-12 rounded-3xl bg-rose-500/5 border border-rose-500/20 flex flex-col items-center gap-8 text-center animate-pulse">
            <div className="relative">
              <div className="w-24 h-24 rounded-full bg-rose-600 flex items-center justify-center shadow-2xl shadow-rose-600/40 relative z-10">
                <i className="fa-solid fa-microphone text-3xl text-white"></i>
              </div>
              <div className="absolute inset-0 bg-rose-500 rounded-full recording-pulse"></div>
            </div>
            <div>
              <h2 className="text-2xl font-bold mb-2">Recording in progress...</h2>
              <p className="text-slate-400">Speak clearly. We'll handle the background noise later.</p>
            </div>
            <button 
              onClick={stopRecording}
              className="px-10 py-4 bg-white text-rose-600 font-bold rounded-full hover:bg-slate-100 transition-all shadow-xl"
            >
              Stop Recording
            </button>
          </div>
        )}

        {/* Original Audio Preview & Enhancement Action */}
        {result.original.blob && !isRecording && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <i className="fa-solid fa-file-audio text-indigo-400 text-xl"></i>
                <span className="font-medium text-slate-300">{result.original.name}</span>
              </div>
              <button 
                onClick={reset}
                className="text-sm text-slate-500 hover:text-white transition-colors flex items-center gap-2"
              >
                <i className="fa-solid fa-rotate-left"></i> Start Over
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
              <div className="space-y-6">
                <AudioPlayer url={result.original.url!} title="Original File" accentColor="slate" />
                
                {result.status === AppStatus.IDLE && (
                  <button 
                    onClick={handleEnhance}
                    className="w-full py-5 bg-indigo-600 hover:bg-indigo-500 text-white font-black rounded-2xl shadow-xl shadow-indigo-500/20 transition-all flex items-center justify-center gap-3"
                  >
                    <i className="fa-solid fa-wand-sparkles"></i>
                    ENHANCE AUDIO QUALITY
                  </button>
                )}

                {result.status === AppStatus.PROCESSING && (
                  <div className="w-full p-6 rounded-2xl bg-indigo-600/10 border border-indigo-500/20 flex flex-col items-center gap-4">
                    <div className="w-8 h-8 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-indigo-400 font-bold">Enhancing Audio via Local API...</p>
                    <p className="text-xs text-slate-500 text-center">Processing waveform, reducing noise, and generating AI insights.</p>
                  </div>
                )}

                {result.status === AppStatus.ERROR && (
                  <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-400 text-sm flex items-start gap-3">
                    <i className="fa-solid fa-circle-exclamation mt-1"></i>
                    <div>
                      <p className="font-bold">Enhancement Failed</p>
                      <p>{result.error}</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Enhancement Results */}
              <div className="space-y-6">
                {result.enhanced && (
                  <>
                    <AudioPlayer url={result.enhanced.url!} title="Enhanced Quality" accentColor="emerald" />
                    
                    {insights && (
                      <div className="p-6 rounded-2xl bg-indigo-600/5 border border-indigo-500/20">
                        <div className="flex items-center gap-2 text-indigo-400 mb-3">
                          <i className="fa-solid fa-brain text-xs"></i>
                          <h4 className="text-xs font-bold uppercase tracking-widest">AI Content Insights</h4>
                        </div>
                        <p className="text-slate-300 italic text-sm leading-relaxed">
                          "{insights}"
                        </p>
                      </div>
                    )}
                  </>
                )}
                
                {!result.enhanced && result.status !== AppStatus.PROCESSING && (
                  <div className="h-48 rounded-2xl bg-slate-900/30 border border-slate-800 flex flex-col items-center justify-center text-slate-600 italic text-sm">
                    <i className="fa-solid fa-ghost text-4xl mb-4 opacity-20"></i>
                    Enhanced preview will appear here
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Footer Info */}
      <footer className="mt-24 pt-8 border-t border-slate-900 text-center space-y-4">
        <p className="text-slate-500 text-sm">
          Powered by Gemini 3.0 & Local Audio Processing Pipeline
        </p>
        <div className="flex justify-center gap-6">
          <span className="flex items-center gap-2 text-xs text-slate-600">
            <i className="fa-solid fa-shield-halved"></i> Privacy First
          </span>
          <span className="flex items-center gap-2 text-xs text-slate-600">
            <i className="fa-solid fa-bolt"></i> Low Latency
          </span>
        </div>
      </footer>
    </div>
  );
};

export default App;
