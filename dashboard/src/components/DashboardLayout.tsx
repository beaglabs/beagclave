import React from 'react';
import { Box, Toolbar, Typography, Badge, IconButton, Tooltip } from '@mui/material';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import {
  Dashboard as DashboardIcon,
  Computer as ComputerIcon,
  Storage as StorageIcon,
  Security as SecurityIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Notifications as NotificationsIcon,
} from '@mui/icons-material';
import { useMsal } from '@azure/msal-react';

const navItems = [
  { label: 'Overview', icon: <DashboardIcon />, path: '/' },
  { label: 'Sessions', icon: <ComputerIcon />, path: '/sessions' },
  { label: 'Data Explorer', icon: <StorageIcon />, path: '/data' },
  { label: 'Compliance', icon: <SecurityIcon />, path: '/compliance' },
  { label: 'Settings', icon: <SettingsIcon />, path: '/settings' },
];

export default function DashboardLayout({ children }: { children?: React.ReactNode }) {
  const { pathname } = useLocation();
  const { logout } = useMsal();

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <Box
        component="nav"
        sx={{
          width: 240,
          flexShrink: 0,
          borderRight: '1px solid',
          borderColor: 'divider',
          bgcolor: 'background.paper',
        }}
      >
        <Box sx={{ overflowY: 'auto', mt: 2 }}>
          {navItems.map((item) => (
            <Tooltip key={item.path} title={item.label} placement="right">
              <IconButton
                color="inherit"
                component={NavLink}
                to={item.path}
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  width: '100%',
                  py: 1.5,
                  color: pathname === item.path ? 'primary.main' : 'text.secondary',
                  bgcolor: pathname === item.path ? 'action.selected' : 'transparent',
                  '&:hover': {
                    bgcolor: 'action.hover',
                  },
                }}
              >
                <Badge
                  color="primary"
                  variant={pathname === item.path ? 'dot' : 'standard'}
                  overlap="circular"
                >
                  {item.icon}
                </Badge>
                <Typography variant="caption" sx={{ mt: 0.5 }}>
                  {item.label}
                </Typography>
              </IconButton>
            </Tooltip>
          ))}
          <Tooltip title="Logout" placement="right">
            <IconButton
              color="inherit"
              onClick={() => logout()}
              sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                width: '100%',
                py: 1.5,
              }}
            >
              <LogoutIcon />
              <Typography variant="caption" sx={{ mt: 0.5 }}>
                Logout
              </Typography>
            </IconButton>
          </Tooltip>
        </Box>
      </Box>
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar />
        {children}
        <Outlet />
      </Box>
    </Box>
  );
}
