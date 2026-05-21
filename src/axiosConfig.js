import axios from 'axios';

// Configuración global de axios
const API_URL = import.meta.env.VITE_API_URL || 'http://api.plagavision.djrbweb.com:5000';

// Crear instancia de axios con la configuración base
const axiosInstance = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para manejar errores
axiosInstance.interceptors.response.use(
  response => response,
  error => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export default axiosInstance;