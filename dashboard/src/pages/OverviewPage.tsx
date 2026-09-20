import React, { useEffect, useState } from 'react';
import { Box, Grid, Card, CardContent, Typography, Chip } from '@mui/material';
import { Computer, Storage, Security, Timeline } from '@mui/icons-material';
import { useMsal } from '@azure/msal-react';

interface EnclaveStatus {
  enclaveName: string;
  usersOnline: number;
  activeSessions: number;
  storageUsedGB: number;
  dataClassified: {
    cui: number;
    itar: number;
    ear: number;
  };
  compliance: {
    score: number;
    pendingViolations: number;
  };
}

export default function OverviewPage() {
  const { accounts } = useMsal();
  const [status, setStatus] = useState<EnclaveStatus | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEnclaveStatus();
    const interval = setInterval(fetchEnclaveStatus, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchEnclaveStatus = async () => {
    try {
      setLoading(true);
      const account = accounts[0];
      const tokenResponse = await account.idToken;
      
      const response = await fetch('/api/status', {
        headers: {
          Authorization: `Bearer ${tokenResponse}`,
        },
      });
      
      const data = await response.json();
      setStatus(data);
    } catch (error) {
      console.error('Failed to fetch enclave status:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading || !status) {
    return (
      <Box>
        <Typography>Loading enclave status...</Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Beagclave Enclave Dashboard
      </Typography>
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        User: {accounts[0]?.username}
      </Typography>

      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <Computer color="primary" />
                <Typography variant="h6">Active Sessions</Typography>
              </Box>
              <Typography variant="h3">{status.activeSessions}</Typography>
              <Typography variant="body2" color="text.secondary">
                {status.usersOnline} users online
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <Storage color="primary" />
                <Typography variant="h6">Storage</Typography>
              </Box>
              <Typography variant="h3">{status.storageUsedGB.toFixed(1)} GB</Typography>
              <Typography variant="body2" color="text.secondary">
                CUI/ITAR/EAR protected
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <Security color="primary" />
                <Typography variant="h6">Compliance</Typography>
              </Box>
              <Typography variant="h3">{status.compliance.score}%</Typography>
              <Typography variant="body2" color="text.secondary">
                {status.compliance.pendingViolations} violations pending
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <Timeline color="primary" />
                <Typography variant="h6">Data Classification</Typography>
              </Box>
              <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                <Chip label={`CUI: ${status.dataClassified.cui}`} color="error" size="small" />
                <Chip label={`ITAR: ${status.dataClassified.itar}`} color="primary" size="small" />
                <Chip label={`EAR: ${status.dataClassified.ear}`} color="success" size="small" />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box sx={{ mt: 4 }}>
        <Typography variant="h6" gutterBottom>
          Recent Security Events
        </Typography>
        <Card>
          <CardContent>
            <Typography variant="body2" color="text.secondary">
              No critical events in the last 24 hours
            </Typography>
          </CardContent>
        </Card>
      </Box>
    </Box>
  );
}
