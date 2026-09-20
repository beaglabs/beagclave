import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useIsAuthenticated } from '@azure/msal-react';
import DashboardLayout from './components/DashboardLayout';
import OverviewPage from './pages/OverviewPage';
import SessionsPage from './pages/SessionsPage';
import DataExplorerPage from './pages/DataExplorerPage';
import CompliancePage from './pages/CompliancePage';
import SettingsPage from './pages/SettingsPage';

function App() {
  const isAuthenticated = useIsAuthenticated();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return (
    <DashboardLayout>
      <Routes>
        <Route path="/" element={<OverviewPage />} />
        <Route path="/sessions" element={<SessionsPage />} />
        <Route path="/data" element={<DataExplorerPage />} />
        <Route path="/compliance" element={<CompliancePage />} />
        <Route path="/settings" element={<SettingsPage />} />
      </Routes>
    </DashboardLayout>
  );
}

export default App;