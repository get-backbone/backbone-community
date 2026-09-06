// Authentication utility functions
const AuthUtils = {
  /**
   * Get JWT access token from localStorage
   * @returns {string|null} Access token or null
   */
  getAccessToken() {
    return localStorage.getItem('accessToken');
  },
  
  /**
   * Get refresh token from localStorage
   * @returns {string|null} Refresh token or null
   */
  getRefreshToken() {
    return localStorage.getItem('refreshToken');
  },
  
  /**
   * Check if token is expired
   * @returns {boolean} True if token is expired or missing
   */
  isTokenExpired() {
    const expiresAt = localStorage.getItem('tokenExpiresAt');
    if (!expiresAt) return true;
    return new Date(expiresAt) < new Date();
  },
  
  /**
   * Store JWT tokens and user data in localStorage
   * @param {Object} authResponse - AuthResponse with tokens and user
   */
  storeTokens(authResponse) {
    if (authResponse.accessToken) {
      localStorage.setItem('accessToken', authResponse.accessToken);
    }
    if (authResponse.idToken) {
      localStorage.setItem('idToken', authResponse.idToken);
    }
    if (authResponse.refreshToken) {
      localStorage.setItem('refreshToken', authResponse.refreshToken);
    }
    if (authResponse.expiresAt) {
      localStorage.setItem('tokenExpiresAt', authResponse.expiresAt);
    }
    if (authResponse.user) {
      // Support both 'id' and 'sub' fields (sub is the actual field in AuthUser)
      const userId = authResponse.user.id || authResponse.user.sub;
      if (userId) {
        localStorage.setItem('userId', userId);
      }
      // Do not store username from login response - it's the email from Cognito
      // Username will be populated from candidate profile fetch (which provides first name only)
      // For refresh token requests, we extract username from ID token when needed
    }
  },
  
  /**
   * Clear all authentication data from localStorage
   */
  clearAuthData() {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('idToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('tokenExpiresAt');
    localStorage.removeItem('userId');
    localStorage.removeItem('username');
    if (typeof ActorSession !== 'undefined') {
      ActorSession.clear();
    }
  },
  
  /**
   * Refresh access token using refresh token
   * @returns {Promise<boolean>} True if refresh successful
   */
  async refreshToken() {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      return false;
    }
    
    try {
      // Double-check refreshToken still exists before making request (defense against race conditions)
      const refreshTokenCheck = this.getRefreshToken();
      if (!refreshTokenCheck) {
        return false;
      }
      
      // Include ID token so backend can extract username for SECRET_HASH calculation
      // ID token is already stored, so we just send it - no additional complexity
      const idToken = localStorage.getItem('idToken');
      
      const refreshRequest = { refreshToken: refreshTokenCheck };
      if (idToken) {
        refreshRequest.idToken = idToken;
      }
      
      const response = await fetch(AppConfig.apiUrl(AppConfig.API_PATHS.AUTH_REFRESH), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(refreshRequest)
      });
      
      if (!response.ok) {
        return false;
      }
      
      const authResponse = await response.json();
      if (authResponse.success) {
        this.storeTokens(authResponse);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error refreshing token:', error);
      return false;
    }
  },
  
  /**
   * Get candidate ID from localStorage
   * @returns {string|null} Candidate ID or null
   */
  getCandidateId() {
    return localStorage.getItem('userId');
  },
  
  /**
   * Get username from localStorage
   * @returns {string|null} Username or null
   */
  getUsername() {
    return localStorage.getItem('username');
  },
  
  /**
   * Get first name from full username
   * @param {string} fullName - Full name (e.g., "Andrew Eells")
   * @returns {string} First name only
   */
  getFirstName(fullName) {
    if (!fullName) return 'User';
    return fullName.split(' ')[0];
  },
  
  /**
   * Get display name with greeting
   * @param {string} fullName - Full name
   * @returns {string} "Hi, [FirstName]"
   */
  getDisplayName(fullName) {
    const firstName = this.getFirstName(fullName);
    return `Hi, ${firstName}`;
  },
  
  /**
   * Store user data in localStorage (legacy method for compatibility)
   */
  storeUserData(userId, username = null) {
    if (userId) localStorage.setItem('userId', userId);
    if (username) localStorage.setItem('username', username);
  },
  
  /**
   * Clear user data from localStorage (legacy method for compatibility)
   */
  clearUserData() {
    this.clearAuthData();
  },
  
  /**
   * Check if user is authenticated (has valid token)
   * @returns {boolean}
   */
  isAuthenticated() {
    const token = this.getAccessToken();
    if (!token) return false;
    
    // Check if token is expired
    if (this.isTokenExpired()) {
      // Try to refresh token synchronously (will be async in practice)
      // For now, just return false if expired
      return false;
    }
    
    return true;
  },
  
  /**
   * Require authentication - redirect to login if not authenticated
   * @returns {boolean} True if authenticated
   */
  requireAuth() {
    if (!this.isAuthenticated()) {
      window.location.href = AppConfig.ROUTES.LOGIN;
      return false;
    }
    return true;
  },

  /**
   * Check if a string looks like an email address
   * @param {string} str - String to check
   * @returns {boolean} True if string contains @ symbol
   */
  isEmail(str) {
    return str && str.includes('@');
  },

  /**
   * Fetch candidate profile to populate username in localStorage
   * Only fetches if username is missing or is an email address
   * Uses ApiClient for centralized routing, authentication, and error handling
   * Uses the partial endpoint to avoid attempting to fetch non-existent resume data
   * (e.g., immediately after registration before resume upload)
   * @returns {Promise<boolean>} True if username was fetched and set, false otherwise
   */
  async ensureUsernameFromProfile() {
    const username = this.getUsername();
    const candidateId = this.getCandidateId();
    
    // Only fetch if username is missing or looks like an email
    if (!username || this.isEmail(username)) {
      if (!candidateId) {
        return false; // Can't fetch without candidate ID
      }
      
      if (typeof ActorSession === 'undefined' || typeof ApiClient === 'undefined') {
        console.debug('ActorSession/ApiClient not available, skipping username fetch');
        return false;
      }
      
      try {
        const profile = await ActorSession.load();
        return !!(profile && profile.username);
      } catch (error) {
        // Log error for debugging but don't throw
        // ApiClient handles authentication errors and redirects automatically
        console.debug('Could not fetch profile for username:', error);
      }
    }
    
    return false; // Username was already set or fetch failed
  }
};

