// Settings page: LinkedIn linking and other account options
document.addEventListener('DOMContentLoaded', function() {
    if (!AuthUtils.requireAuth()) {
        return;
    }

    checkLinkedInStatus();

    const linkBtn = document.getElementById('linkLinkedInBtn');
    if (linkBtn) {
        linkBtn.addEventListener('click', function() {
            initiateLinkedInLinking();
        });
    }
});

async function initiateLinkedInLinking() {
    const accessToken = AuthUtils.getAccessToken();
    if (!accessToken) {
        showLinkedInMessage(document.getElementById('linkedinMessage'), 'You must be logged in to link your LinkedIn account.', 'error');
        return;
    }

    const linkedInLinkHref = ActorSession.link('link-linkedin');
    if (!linkedInLinkHref) {
        showLinkedInMessage(document.getElementById('linkedinMessage'), 'LinkedIn linking is not available for this account.', 'error');
        return;
    }

    const linkBtn = document.getElementById('linkLinkedInBtn');
    if (linkBtn) {
        linkBtn.disabled = true;
        linkBtn.textContent = 'Linking...';
    }

    try {
        const linkUrl = AppConfig.apiUrl(linkedInLinkHref);
        const response = await fetch(linkUrl, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });

        if (!response.ok) {
            const errorText = await response.text();
            let errorMessage = 'Failed to initiate LinkedIn linking';
            try {
                const errorData = JSON.parse(errorText);
                errorMessage = errorData.error || errorMessage;
            } catch (e) {
                if (errorText) {
                    errorMessage = errorText;
                }
            }
            showLinkedInMessage(document.getElementById('linkedinMessage'), errorMessage, 'error');
            resetLinkedInLinkButton(linkBtn);
            return;
        }

        const responseData = await response.json();
        const authorizationUrl = responseData.authorizationUrl;
        if (authorizationUrl) {
            window.location.href = authorizationUrl;
        } else {
            throw new Error('Authorization URL not found in response');
        }
    } catch (error) {
        console.error('Error initiating LinkedIn linking:', error);
        showLinkedInMessage(document.getElementById('linkedinMessage'), 'Failed to initiate LinkedIn linking: ' + error.message, 'error');
        resetLinkedInLinkButton(linkBtn);
    }
}

async function checkLinkedInStatus() {
    try {
        const profile = await ActorSession.load();
        if (ActorSession.link('link-linkedin')) {
            updateLinkedInStatus('not-linked');
        } else if (profile && profile.linkedInSub) {
            updateLinkedInStatus('linked');
        } else {
            updateLinkedInStatus('not-linked');
        }
    } catch (error) {
        console.error('Failed to check LinkedIn status:', error);
        updateLinkedInStatus('unknown');
    }
}

function updateLinkedInStatus(status) {
    const statusDiv = document.getElementById('linkedinStatus');
    const linkBtn = document.getElementById('linkLinkedInBtn');
    const linkedInLinkHref = ActorSession.link('link-linkedin');

    if (!statusDiv || !linkBtn) {
        return;
    }

    switch (status) {
        case 'linked':
            statusDiv.innerHTML = '<span style="color: var(--success-color, #10b981);">✓ LinkedIn account linked</span>';
            linkBtn.style.display = 'none';
            break;
        case 'not-linked':
            statusDiv.innerHTML = '<span style="color: var(--text-muted);">Not linked</span>';
            linkBtn.style.display = linkedInLinkHref ? 'inline-block' : 'none';
            break;
        case 'error':
            statusDiv.innerHTML = '<span style="color: var(--error-color, #ef4444);">Error linking account</span>';
            linkBtn.style.display = linkedInLinkHref ? 'inline-block' : 'none';
            break;
        default:
            statusDiv.innerHTML = '<span style="color: var(--text-muted);">Checking status...</span>';
            linkBtn.style.display = 'none';
    }
}

function resetLinkedInLinkButton(linkBtn) {
    if (!linkBtn) {
        return;
    }
    linkBtn.disabled = false;
    linkBtn.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" style="vertical-align: middle; margin-right: 8px;"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>Link LinkedIn Account';
}

function showLinkedInMessage(container, message, type) {
    if (!container) {
        return;
    }
    const colors = {
        success: 'var(--success-color, #10b981)',
        warning: 'var(--warning-color, #f59e0b)',
        error: 'var(--error-color, #ef4444)'
    };
    container.innerHTML = `<div style="padding: 12px; border-radius: 4px; background-color: ${colors[type]}20; color: ${colors[type]}; border: 1px solid ${colors[type]}40;">${escapeHtml(message)}</div>`;
    if (type === 'success') {
        setTimeout(function() {
            container.innerHTML = '';
        }, 5000);
    }
}
