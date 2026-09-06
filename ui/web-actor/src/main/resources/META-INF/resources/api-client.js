// API client utility for consistent fetch calls
const ApiClient = {
  /**
   * Make a fetch request with consistent error handling
   * @param {string} url - Full URL or root-relative API path (resolved via AppConfig.apiUrl)
   * @param {Object} options - Fetch options
   * @returns {Promise<Object>} Parsed JSON response
   */
  async request(url, options = {}) {
    const fullUrl = url.startsWith('http') ? url : AppConfig.apiUrl(url);
    const { headers: optionHeaders, ...restOptions } = options;

    // Get JWT token and add to headers
    const headers = {
      'Content-Type': 'application/json',
      ...optionHeaders
    };
    
    const accessToken = AuthUtils.getAccessToken();
    if (accessToken && !AuthUtils.isTokenExpired()) {
      headers['Authorization'] = `Bearer ${accessToken}`;
    } else if (accessToken && AuthUtils.isTokenExpired()) {
      // Try to refresh token before making request
      const refreshed = await AuthUtils.refreshToken();
      if (refreshed) {
        const newToken = AuthUtils.getAccessToken();
        if (newToken) {
          headers['Authorization'] = `Bearer ${newToken}`;
        }
      } else {
        // Refresh failed, clear auth and redirect to login
        AuthUtils.clearAuthData();
        window.location.href = AppConfig.ROUTES.LOGIN;
        throw new ApiError(401, 'Unauthorized', { error: 'Token expired and refresh failed' });
      }
    }

    const mergedOptions = { ...restOptions, headers };
    
    try {
      const response = await fetch(fullUrl, mergedOptions);
      const responseText = await response.text();
      
      // Try to parse as JSON
      let data = null;
      try {
        data = responseText ? JSON.parse(responseText) : null;
      } catch (e) {
        // Not JSON, return as text
        data = { raw: responseText };
      }
      
      // Handle 401 Unauthorized - token may have expired
      if (response.status === 401) {
        // Try to refresh token once
        const refreshed = await AuthUtils.refreshToken();
        if (refreshed) {
          // Retry the request with new token
          const newToken = AuthUtils.getAccessToken();
          if (newToken) {
            headers['Authorization'] = `Bearer ${newToken}`;
            mergedOptions.headers = headers;
            const retryResponse = await fetch(fullUrl, mergedOptions);
            const retryText = await retryResponse.text();
            let retryData = null;
            try {
              retryData = retryText ? JSON.parse(retryText) : null;
            } catch (e) {
              retryData = { raw: retryText };
            }
            if (!retryResponse.ok) {
              throw new ApiError(retryResponse.status, retryResponse.statusText, retryData);
            }
            return { ok: true, status: retryResponse.status, data: retryData };
          }
        }
        // Refresh failed or no token, clear auth and redirect
        AuthUtils.clearAuthData();
        window.location.href = AppConfig.ROUTES.LOGIN;
        throw new ApiError(401, 'Unauthorized', { error: 'Authentication required' });
      }
      
      if (!response.ok) {
        throw new ApiError(response.status, response.statusText, data);
      }
      
      return { ok: true, status: response.status, data };
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(null, 'Network Error', { error: error.message });
    }
  },
  
  /**
   * GET request
   */
  async get(url, options = {}) {
    return this.request(url, { ...options, method: 'GET' });
  },
  
  /**
   * POST request
   */
  async post(url, data, options = {}) {
    return this.request(url, {
      ...options,
      method: 'POST',
      body: JSON.stringify(data)
    });
  },
  
  /**
   * Build URL with query parameters
   */
  buildUrl(path, params = {}) {
    const resolved = path.startsWith('http') ? path : AppConfig.apiUrl(path);
    const url = resolved.startsWith('http')
      ? new URL(resolved)
      : new URL(resolved, window.location.origin);
    Object.keys(params).forEach(key => {
      if (params[key] !== null && params[key] !== undefined) {
        url.searchParams.append(key, params[key]);
      }
    });
    return url.toString();
  }
};

/**
 * Custom API Error class
 */
class ApiError extends Error {
  constructor(status, statusText, data) {
    super(statusText || 'API Error');
    this.status = status;
    this.statusText = statusText;
    this.data = data;
  }
  
  getMessage() {
    if (this.data?.error) return this.data.error;
    if (this.data?.errorMessage) return this.data.errorMessage;
    if (this.data?.raw) return this.data.raw;
    return this.message;
  }
}

