// UI utility functions for loading states, error handling, etc.
const UIUtils = {
  /**
   * Show/hide loading state
   */
  showLoading(show = true) {
    if (show) {
      document.body.classList.add('htmx-request');
    } else {
      document.body.classList.remove('htmx-request');
    }
  },
  
  /**
   * Show error message in error div
   */
  showError(element, message) {
    if (!element) return;
    element.textContent = message;
    element.classList.add('show');
  },
  
  /**
   * Hide error message
   */
  hideError(element) {
    if (!element) return;
    element.classList.remove('show');
  },
  
  /**
   * Show/hide loading div
   */
  toggleLoadingDiv(loadingDiv, show) {
    if (!loadingDiv) return;
    if (show) {
      loadingDiv.classList.add('show');
    } else {
      loadingDiv.classList.remove('show');
    }
  },
  
  /**
   * Handle API error and display in error div
   */
  handleApiError(errorDiv, error) {
    if (!errorDiv) return;
    
    let errorMessage = 'An error occurred';
    
    if (error instanceof ApiError) {
      errorMessage = error.getMessage();
      if (error.status) {
        errorMessage = `Error ${error.status}: ${errorMessage}`;
      }
    } else if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    }
    
    this.showError(errorDiv, errorMessage);
  },
  
  /**
   * Format date for display
   */
  formatDate(dateString) {
    if (!dateString) return '';
    return new Date(dateString).toLocaleString();
  },
  
  /**
   * Truncate text with ellipsis
   */
  truncateText(text, maxLength, showStart = 5, showEnd = 10) {
    if (!text || text.length <= maxLength) return text;
    return `${text.substring(0, showStart)}...${text.substring(text.length - showEnd)}`;
  },
  
  /**
   * Build S3 URL for resume download
   */
  buildS3Url(key, truncated = false) {
    const baseUrl = `${AppConfig.S3_LOCALSTACK_URL}/${AppConfig.S3_BUCKET_NAME}`;
    const fullUrl = `${baseUrl}/${key}`;
    
    if (truncated && key.length > 15) {
      const truncatedKey = this.truncateText(key, 15, 5, 10);
      return `${baseUrl}/${truncatedKey}`;
    }
    
    return fullUrl;
  },
  
  /**
   * Redirect with optional delay
   */
  redirect(url, delay = 0) {
    if (delay > 0) {
      setTimeout(() => {
        window.location.href = url;
      }, delay);
    } else {
      window.location.href = url;
    }
  }
};

