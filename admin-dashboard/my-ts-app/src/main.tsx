import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App.tsx';
import { Toaster } from './components/ui/sonner';
import './index.css';
import { useAuthStore } from './stores/authStore';

useAuthStore.getState().hydrate();

createRoot(document.getElementById('root')!).render(
  <BrowserRouter>
    <App />
    <Toaster position="top-center" richColors closeButton />
  </BrowserRouter>,
);
