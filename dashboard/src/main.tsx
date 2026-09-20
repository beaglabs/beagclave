import React from 'react';
import ReactDOM from 'react-dom/client';
import { MsalProvider } from '@azure/msal-react';
import { PublicClientApplication } from '@azure/msal-browser';
import { BrowserRouter } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline } from '@mui/material';
import App from './App';
import { msalConfig } from './config/auth';

const msalInstance = new PublicClientApplication(msalConfig);

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#0065ff',
    },
    secondary: {
      main: '#ff6eb4',
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MsalProvider instance={msalInstance}>
      <BrowserRouter>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <App />
        </ThemeProvider>
      </BrowserRouter>
    </MsalProvider>
  </React.StrictMode>,
);
