// Common utility functions

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function formatJsonResponse(element, jsonText) {
  try {
    const jsonData = JSON.parse(jsonText.trim());
    const formattedJson = JSON.stringify(jsonData, null, 2);
    element.innerHTML = '<div class="json-display">' + escapeHtml(formattedJson) + '</div>';
  } catch (e) {
    console.log('Response is not JSON, leaving as-is');
  }
}

function showLoading(show = true) {
  if (show) {
    document.body.classList.add('htmx-request');
  } else {
    document.body.classList.remove('htmx-request');
  }
}

function showError(element, message) {
  element.textContent = message;
  element.classList.add('show');
}

function hideError(element) {
  element.classList.remove('show');
}

// Check authentication status (using JWT token)
async function checkAuthStatus() {
  // Check if we have a valid token
  const token = AuthUtils.getAccessToken();
  if (!token || AuthUtils.isTokenExpired()) {
    // Try to refresh token if expired
    if (token && AuthUtils.isTokenExpired()) {
      const refreshed = await AuthUtils.refreshToken();
      if (!refreshed) {
        return { authenticated: false };
      }
    } else {
      return { authenticated: false };
    }
  }
  
  // We have a valid token, return user info from localStorage
  const userId = AuthUtils.getCandidateId();
  const username = AuthUtils.getUsername();
  
  return {
    authenticated: true,
    user: {
      id: userId,
      username: username
    }
  };
}

// Update header navigation based on authentication status
function updateHeaderNavigation(authStatus) {
  const navRight = document.querySelector('.nav-right');
  if (!navRight) {
    return;
  }

  if (authStatus.authenticated && authStatus.user) {
    // User is logged in - show notification bell and username dropdown
    // Username comes from PostgreSQL CANDIDATES table (stored in localStorage after profile fetch)
    // Server-side truncation ensures only first name is stored (for security)
    // Falls back to 'User' if not yet loaded
    const username = localStorage.getItem('username') || 'User';
    const displayName = `Hi, ${username}`;
    navRight.innerHTML = `
      <button class="nav-notification-btn" id="notificationBtn" aria-label="Notifications" type="button">
        <svg class="notification-icon" width="16" height="16" viewBox="0 0 16 16" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" clip-rule="evenodd" d="M8 1C10.347 1.00026 12.25 2.90296 12.25 5.25V5.92969C12.25 6.76016 12.5519 7.56241 13.0986 8.1875L13.499 8.64551C13.822 9.01469 14.001 9.48899 14.001 9.97949V11.6162C14.0009 12.2422 13.4922 12.7497 12.8662 12.75H10.7021C10.4668 14.0298 9.34788 15 8 15C6.65212 15 5.53316 14.0298 5.29785 12.75H3.13477C2.50865 12.7499 2.00014 12.2423 2 11.6162V9.97949C2 9.48895 2.17898 9.01472 2.50195 8.64551L2.90234 8.18848C3.44909 7.56333 3.75098 6.7602 3.75098 5.92969V5.25C3.75098 2.90295 5.65302 1.00026 8 1ZM6.85547 12.75C7.04848 13.1912 7.48763 13.5 8 13.5C8.51237 13.5 8.95152 13.1912 9.14453 12.75H6.85547ZM8 2.5C6.48144 2.50026 5.25098 3.73138 5.25098 5.25V5.92969C5.25098 7.12346 4.81717 8.27722 4.03125 9.17578L3.63086 9.63281C3.54706 9.72861 3.50098 9.85222 3.50098 9.97949V11.25H12.501V9.97949C12.501 9.85232 12.4538 9.72856 12.3701 9.63281L11.9697 9.17578C11.1836 8.27722 10.75 7.12362 10.75 5.92969V5.25C10.75 3.73138 9.51855 2.50026 8 2.5Z"></path>
        </svg>
        <span class="notification-dot"></span>
      </button>
      <div class="nav-username-dropdown">
        <button class="nav-username" id="usernameDropdownBtn">
          ${escapeHtml(displayName)} <span class="dropdown-arrow">⌄</span>
        </button>
        <div class="dropdown-menu hidden" id="usernameDropdownMenu">
          <a href="profile.html" class="dropdown-item">Profile</a>
          <a href="settings.html" class="dropdown-item">Settings</a>
          <div class="dropdown-divider"></div>
          <button class="dropdown-item dropdown-item-button" id="logoutBtn">Log out</button>
        </div>
      </div>
    `;
    
    // Add dropdown toggle handler
    const dropdownBtn = document.getElementById('usernameDropdownBtn');
    const dropdownMenu = document.getElementById('usernameDropdownMenu');
    
    if (dropdownBtn && dropdownMenu) {
      dropdownBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        dropdownMenu.classList.toggle('hidden');
      });
      
      // Close dropdown when clicking on a link
      const dropdownLinks = dropdownMenu.querySelectorAll('.dropdown-item');
      dropdownLinks.forEach(link => {
        link.addEventListener('click', function() {
          dropdownMenu.classList.add('hidden');
        });
      });
      
      // Close dropdown when clicking outside
      document.addEventListener('click', function(e) {
        if (!dropdownBtn.contains(e.target) && !dropdownMenu.contains(e.target)) {
          dropdownMenu.classList.add('hidden');
        }
      });
    }
    
    // Add notification button handler
    const notificationBtn = document.getElementById('notificationBtn');
    if (notificationBtn) {
      notificationBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        // TODO: Implement notification dropdown/modal
        console.log('Notifications clicked');
      });
    }
    
    // Add logout handler
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', handleLogout);
    }
  } else {
    // User is not logged in - show login and sign up buttons
    navRight.innerHTML = `
      <a href="login.html" class="nav-link">Log in</a>
      <a href="register.html" class="btn btn-primary btn-small">Sign up</a>
    `;
  }
}

// Handle logout
async function handleLogout(event) {
  event.preventDefault();
  
  // Clear all authentication data (JWT tokens and user data)
  AuthUtils.clearAuthData();
  
  // Redirect to home page
  window.location.href = '/';
}

// Load and inject header into pages
async function loadHeader() {
  const existingHeader = document.querySelector('.header');
  
  if (existingHeader) {
    // Header already exists - just update it
    // Ensure username is fetched from profile if missing or is email
    const usernameWasFetched = await AuthUtils.ensureUsernameFromProfile();
    const authStatus = await checkAuthStatus();
    updateHeaderNavigation(authStatus);
    return;
  }

  // Load header from header.html
  fetch('header.html')
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to load header');
      }
      return response.text();
    })
    .then(async html => {
      // Insert header at the beginning of body
      document.body.insertAdjacentHTML('afterbegin', html);
      // Add class to body to indicate header is present for CSS styling
      document.body.classList.add('has-header');
      
      // Ensure username is fetched from profile if missing or is email
      // This must complete before updating the header navigation
      await AuthUtils.ensureUsernameFromProfile();
      
      // Check auth status and update header (username will now be available)
      const authStatus = await checkAuthStatus();
      updateHeaderNavigation(authStatus);
    })
    .catch(error => {
      console.error('Error loading header:', error);
    });
}

// Load header when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', loadHeader);
} else {
  loadHeader();
}

