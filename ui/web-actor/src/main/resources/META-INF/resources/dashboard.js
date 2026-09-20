document.addEventListener('DOMContentLoaded', function() {
  if (!AuthUtils.requireAuth()) {
    return;
  }

  showLinkedInLinkOutcome();
  positionHelpTooltips();
  bindProfileVisibilityToggle();
});

function showLinkedInLinkOutcome() {
  const urlParams = new URLSearchParams(window.location.search);
  const linkedinStatus = urlParams.get('linkedin');
  const messageDiv = document.getElementById('linkedinMessage');
  if (!linkedinStatus || !messageDiv) {
    return;
  }

  if (linkedinStatus === 'linked') {
    showLinkedInLinkMessage(messageDiv, linkedInSuccessMessage(urlParams), urlParams.get('emailWarning') === 'true' ? 'warning' : 'success');
    completeLinkedInConnect();
    return;
  }

  if (linkedinStatus === 'error') {
    const errorMessage = urlParams.get('message') ? decodeURIComponent(urlParams.get('message')) : 'Failed to link LinkedIn account';
    showLinkedInLinkMessage(messageDiv, errorMessage, 'error');
  }
}

function linkedInSuccessMessage(urlParams) {
  if (urlParams.get('emailWarning') !== 'true') {
    return 'LinkedIn account linked successfully!';
  }
  const linkedInEmail = urlParams.get('linkedInEmail') || 'unknown';
  const accountEmail = urlParams.get('accountEmail') || 'unknown';
  return `The email on your LinkedIn account (${linkedInEmail}) doesn't match the email on your account here (${accountEmail}). This is common if you use a work email on LinkedIn.`;
}

function showLinkedInLinkMessage(container, message, type) {
  const colors = {
    success: 'var(--success-color, #10b981)',
    warning: 'var(--warning-color, #f59e0b)',
    error: 'var(--error-color, #ef4444)'
  };
  container.innerHTML = `<div style="padding: 12px; border-radius: 4px; background-color: ${colors[type]}20; color: ${colors[type]}; border: 1px solid ${colors[type]}40;">${escapeHtml(message)}</div>`;
}

async function completeLinkedInConnect() {
  const actorId = AuthUtils.getCandidateId();
  const refreshToken = AuthUtils.getRefreshToken();
  if (!actorId || !refreshToken) {
    console.warn('Cannot complete LinkedIn linking: missing actorId or refreshToken');
    return;
  }

  try {
    await ActorSession.load();
    const completeHref = ActorSession.link('complete-linkedin-connect');
    if (!completeHref) {
      console.warn('Cannot complete LinkedIn linking: complete-linkedin-connect affordance missing');
      return;
    }

    const response = await fetch(AppConfig.apiUrl(completeHref), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ actorId: actorId, refreshToken: refreshToken })
    });
    if (!response.ok) {
      console.warn('Failed to store refresh token for LinkedIn login:', response.status);
    }
  } catch (error) {
    console.error('Error completing LinkedIn linking:', error);
  }
}

function positionHelpTooltips() {
  const helpIcons = document.querySelectorAll('.help-icon');

  helpIcons.forEach(icon => {
    icon.addEventListener('mouseenter', function() {
      const rect = this.getBoundingClientRect();
      const tooltipText = this.getAttribute('data-tooltip');

      const temp = document.createElement('div');
      temp.style.cssText = 'visibility: hidden; position: fixed; white-space: normal; max-width: 280px; padding: 8px 12px; font-size: 0.8125rem; font-family: "Inter var", "Inter Variable", "Inter", "SF Pro Display", -apple-system, "system-ui", "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;';
      temp.textContent = tooltipText;
      document.body.appendChild(temp);
      const tooltipHeight = temp.offsetHeight;
      document.body.removeChild(temp);

      const left = rect.left + rect.width / 2;
      const top = rect.top - tooltipHeight - 8;

      this.style.setProperty('--tooltip-left', left + 'px');
      this.style.setProperty('--tooltip-top', top + 'px');
      this.style.setProperty('--arrow-left', left + 'px');
      this.style.setProperty('--arrow-top', (rect.top - 3) + 'px');
    });

    icon.addEventListener('click', function(e) {
      e.stopPropagation();
    });
  });
}

function bindProfileVisibilityToggle() {
  const profileToggle = document.getElementById('profileVisibilityToggle');
  const toggleLabel = document.querySelector('.profile-visibility-toggle .toggle-label');
  if (!profileToggle || !toggleLabel) {
    return;
  }

  function updateToggleLabel() {
    toggleLabel.textContent = profileToggle.checked ? 'Profile Enabled' : 'Profile Disabled';
  }

  updateToggleLabel();
  profileToggle.addEventListener('change', updateToggleLabel);
}

