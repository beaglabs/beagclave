import { Configuration } from '@azure/msal-browser';

export const msalConfig: Configuration = {
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID || '',
    authority: `https://login.microsoftonline.us/${import.meta.env.VITE_AZURE_TENANT_ID || ''}`,
    redirectProtocol: 'spa',
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
  system: {
    loggerOptions: [],
  },
};

export const loginRequest = {
  scopes: ['User.Read', 'https://purview.azure.net/user_impersonation'],
};

export const apiConfig = {
  apiEndpoint: import.meta.env.VITE_API_ENDPOINT || 'https://beagclave-api.cui.company.com',
};