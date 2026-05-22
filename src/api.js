// src/api.js
const API_BASE_URL = import.meta.env.VITE_API_URL || '';

// Si hay variable de entorno, úsala; si no, usa ruta relativa (para desarrollo)
export const apiClient = (endpoint) => {
  if (API_BASE_URL) {
    // Producción: usar URL completa
    return `${API_BASE_URL}/api${endpoint}`;
  } else {
    // Desarrollo: usar proxy de Vite
    return `/api${endpoint}`;
  }
};
