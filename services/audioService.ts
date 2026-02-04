
import { GoogleGenAI } from "@google/genai";

const ENHANCE_API_URL = "http://127.0.0.1:7860/direct-enhance";

export const enhanceAudio = async (audioBlob: Blob): Promise<Blob> => {
  const formData = new FormData();
  formData.append('file', audioBlob, 'input_audio.wav');

  try {
    const response = await fetch(ENHANCE_API_URL, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Enhancement API failed with status ${response.status}`);
    }

    return await response.blob();
  } catch (error) {
    console.error("Enhancement error:", error);
    throw error;
  }
};

export const getGeminiInsights = async (audioBlob: Blob): Promise<string> => {
  try {
    const ai = new GoogleGenAI({ apiKey: process.env.API_KEY || '' });
    
    // Convert blob to base64
    const reader = new FileReader();
    const base64Promise = new Promise<string>((resolve) => {
      reader.onloadend = () => {
        const base64 = (reader.result as string).split(',')[1];
        resolve(base64);
      };
      reader.readAsDataURL(audioBlob);
    });
    
    const base64Data = await base64Promise;

    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: {
        parts: [
          { inlineData: { data: base64Data, mimeType: 'audio/wav' } },
          { text: "Briefly summarize what is being said in this audio and describe its quality (e.g., noisy, clear, muffled). Keep it to 2-3 sentences." }
        ]
      }
    });

    return response.text || "No insights available.";
  } catch (error) {
    console.warn("Gemini insights error:", error);
    return "Could not generate AI insights at this time.";
  }
};
