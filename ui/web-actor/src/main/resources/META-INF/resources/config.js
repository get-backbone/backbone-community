// Application configuration
const LOCAL_DEV_API_ORIGIN = 'http://localhost:8500';

/**
 * Resolves a root-relative API path for fetch/HTMX. Uses path-only URLs on the same host as the UI
 * (int/prod ALB); prepends actor-bff origin only for local dev (UI on web-actor, API on :8500).
 * @param {string} path - Must start with / (e.g. /auth/login)
 * @returns {string} Path like /auth/login or absolute URL for local dev
 */
function apiUrl(path) {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return `${LOCAL_DEV_API_ORIGIN}${normalizedPath}`;
  }
  return normalizedPath;
}

/**
 * App document filenames (no leading slash).
 */
const ROUTES = {
  DASHBOARD: 'dashboard.html',
  PROFILE: 'profile.html',
  LOGIN: 'login.html',
  REGISTER: 'register.html',
  SETTINGS: 'settings.html',
  FORGOT_PASSWORD: 'forgot-password.html',
  RESET_PASSWORD: 'reset-password.html',
};

const AppConfig = {
  apiUrl,

  /** Browser URL for OAuth token exchange + delegated outcomes (auth-service redirects here). */
  AUTH_BROWSER_ENTRY_PATH: '/auth/callback.html',

  // S3 configuration
  S3_BUCKET_NAME: 'backbone-documents',
  S3_LOCALSTACK_URL: 'http://localhost:4566',

  ROUTES,

  // API paths
  API_PATHS: {
    AUTH_LOGIN: '/auth/login',
    AUTH_REGISTER: '/auth/register',
    AUTH_REFRESH: '/auth/tokens/refresh',
    AUTH_FORGOT_PASSWORD: '/auth/forgot-password',
    AUTH_RESET_PASSWORD: '/auth/reset-password',
    AUTH_LINKEDIN_LOGIN: '/auth/linkedin/login',
    AUTH_GOOGLE_LOGIN: '/auth/google/login',

    /**
     * Bootstrap path for the authenticated HAL actor root.
     * Prefer ActorSession.load() / ActorSession.link(rel) after the first fetch.
     * @param {string} actorId - The actor ID (UUID)
     * @returns {string} The API path for the actor profile
     */
    ACTOR_PROFILE: (actorId) => `/actors/${encodeURIComponent(actorId)}`
  }
};
