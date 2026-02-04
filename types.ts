
export interface AudioState {
  blob: Blob | null;
  url: string | null;
  name: string;
}

export enum AppStatus {
  IDLE = 'IDLE',
  RECORDING = 'RECORDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  ERROR = 'ERROR'
}

export interface EnhancementResult {
  original: AudioState;
  enhanced: AudioState | null;
  status: AppStatus;
  error?: string;
}
