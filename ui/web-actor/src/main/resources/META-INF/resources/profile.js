// Load and display user profile on page load
window.addEventListener('DOMContentLoaded', async function() {
    const loadingDiv = document.getElementById('loading');
    const errorDiv = document.getElementById('error');
    const profileDiv = document.getElementById('profile');

    if (loadingDiv) {
        loadingDiv.classList.add('show');
    }
    if (errorDiv) {
        errorDiv.classList.remove('show');
    }

    if (!AuthUtils.requireAuth()) {
        return;
    }

    try {
        console.log('Fetching HAL actor profile');

        const profileData = await ActorSession.load(true);

        if (loadingDiv) {
            loadingDiv.classList.remove('show');
        }

        if (!profileData) {
            if (errorDiv) {
                showError(errorDiv, 'Unable to load actor profile.');
            }
            return;
        }

        await displayProfile(profileData, profileDiv);

        if (typeof updateHeaderNavigation === 'function') {
            checkAuthStatus().then(authStatus => {
                updateHeaderNavigation(authStatus);
            });
        }
    } catch (error) {
        console.error('Error fetching profile:', error);
        if (loadingDiv) {
            loadingDiv.classList.remove('show');
        }
        if (errorDiv) {
            showError(errorDiv, 'Failed to load profile: ' + error.message);
        }
    }
});

async function displayProfile(profile, profileDiv) {
    if (!profileDiv) {
        return;
    }

    fillCandidateSection(profile);
    profileDiv.hidden = false;
    bindResumeUploadInteractions();
    await refreshDocumentsList();
}

function fillCandidateSection(profile) {
    setProfileField('profile-name-item', 'profile-name', profile.username);
    setProfileField('profile-email-item', 'profile-email', profile.emailAddress);
    setProfileField(
        'profile-registered-item',
        'profile-registered',
        profile.timestamp ? new Date(profile.timestamp).toLocaleString() : null
    );
}

function setProfileField(itemId, valueId, value) {
    const item = document.getElementById(itemId);
    const valueEl = document.getElementById(valueId);
    if (!item || !valueEl) {
        return;
    }
    if (!value) {
        item.hidden = true;
        valueEl.textContent = '';
        return;
    }
    item.hidden = false;
    valueEl.textContent = value;
}

function cloneTemplate(templateId) {
    const template = document.getElementById(templateId);
    return template.content.firstElementChild.cloneNode(true);
}

let pendingResumeFiles = [];

function bindResumeUploadInteractions() {
    const dropzone = document.getElementById('resume-upload-box');
    const fileInput = document.getElementById('resume-file-input');
    const uploadBtn = document.getElementById('resume-upload-btn');

    if (!dropzone || !fileInput) {
        return;
    }

    pendingResumeFiles = [];

    const openPicker = () => {
        // Reset value so choosing the same file again still fires change and can be re-added after remove.
        fileInput.value = '';
        fileInput.click();
    };

    dropzone.addEventListener('click', event => {
        if (event.target.closest('button') || event.target.closest('.cv-selected-files')) {
            return;
        }
        openPicker();
    });
    dropzone.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            openPicker();
        }
    });

    ['dragenter', 'dragover'].forEach(type => {
        dropzone.addEventListener(type, event => {
            event.preventDefault();
            dropzone.classList.add('is-dragover');
        });
    });
    ['dragleave', 'drop'].forEach(type => {
        dropzone.addEventListener(type, event => {
            event.preventDefault();
            dropzone.classList.remove('is-dragover');
        });
    });
    dropzone.addEventListener('drop', event => {
        const files = event.dataTransfer && event.dataTransfer.files;
        if (!files || files.length === 0) {
            return;
        }
        setPendingResumeFiles(mergeFileLists(pendingResumeFiles, files));
    });

    fileInput.addEventListener('change', () => {
        if (!fileInput.files || fileInput.files.length === 0) {
            return;
        }
        // Native picker replaces FileList each browse; merge into the pending queue.
        setPendingResumeFiles(mergeFileLists(pendingResumeFiles, fileInput.files));
    });
    if (uploadBtn) {
        uploadBtn.addEventListener('click', event => {
            event.stopPropagation();
            uploadResumeDocuments();
        });
    }
}

function mergeFileLists(existingFiles, incomingFiles) {
    const byIdentity = new Map();
    const addFile = file => {
        const key = `${file.name}:${file.size}:${file.lastModified}`;
        byIdentity.set(key, file);
    };
    Array.from(existingFiles || []).forEach(addFile);
    Array.from(incomingFiles || []).forEach(addFile);
    return Array.from(byIdentity.values());
}

function setPendingResumeFiles(files) {
    pendingResumeFiles = Array.from(files || []);
    const fileInput = document.getElementById('resume-file-input');
    if (fileInput) {
        assignFilesToInput(fileInput, pendingResumeFiles);
    }
    updateSelectedResumeFileLabel();
}

function assignFilesToInput(fileInput, files) {
    const transfer = new DataTransfer();
    files.forEach(file => transfer.items.add(file));
    fileInput.files = transfer.files;
}

function updateSelectedResumeFileLabel() {
    const selectedDiv = document.getElementById('resume-selected-file');
    const uploadBtn = document.getElementById('resume-upload-btn');
    if (!selectedDiv) {
        return;
    }

    selectedDiv.replaceChildren();

    const files = pendingResumeFiles;
    if (files.length === 0) {
        selectedDiv.hidden = true;
        if (uploadBtn) {
            uploadBtn.disabled = true;
            uploadBtn.textContent = 'Upload';
        }
        return;
    }

    selectedDiv.hidden = false;
    files.forEach((file, index) => {
        const chip = cloneTemplate('cv-file-chip-template');
        chip.querySelector('[data-field="name"]').textContent = file.name;
        chip.querySelector('[data-field="size"]').textContent = formatDocumentSize(file.size);
        const removeBtn = chip.querySelector('[data-field="remove"]');
        removeBtn.setAttribute('aria-label', `Remove ${file.name}`);
        removeBtn.addEventListener('click', event => {
            event.stopPropagation();
            setPendingResumeFiles(pendingResumeFiles.filter((_, fileIndex) => fileIndex !== index));
        });
        selectedDiv.appendChild(chip);
    });

    if (uploadBtn) {
        uploadBtn.disabled = false;
        uploadBtn.textContent = files.length === 1 ? 'Upload' : `Upload ${files.length}`;
    }
}

async function refreshDocumentsList() {
    const loadingEl = document.getElementById('documents-loading');
    const emptyEl = document.getElementById('documents-empty');
    const errorEl = document.getElementById('documents-error');
    const listEl = document.getElementById('documents-list-items');
    if (!listEl) {
        return;
    }

    showDocumentsState({ loading: true });

    const actorId = AuthUtils.getCandidateId();
    if (!actorId) {
        showDocumentsState({ empty: true });
        if (emptyEl) {
            emptyEl.querySelector('.cv-empty-title').textContent = 'Unable to resolve actor id.';
            emptyEl.querySelector('.cv-empty-hint').textContent = '';
        }
        return;
    }

    try {
        const documentsHref = ActorSession.link('documents') || `/documents?actorId=${encodeURIComponent(actorId)}`;
        const response = await ApiClient.get(documentsHref);
        const documents = normalizeDocuments(response.data);
        renderDocumentsList(documents, listEl, actorId);
    } catch (error) {
        console.error('Failed to load documents:', error);
        const message = error instanceof ApiError ? error.getMessage() : error.message;
        showDocumentsState({ error: true });
        if (errorEl) {
            errorEl.textContent = `Failed to load documents: ${message}`;
        }
    }
}

function showDocumentsState({ loading = false, empty = false, error = false, list = false } = {}) {
    const loadingEl = document.getElementById('documents-loading');
    const emptyEl = document.getElementById('documents-empty');
    const errorEl = document.getElementById('documents-error');
    const listEl = document.getElementById('documents-list-items');

    if (loadingEl) {
        loadingEl.hidden = !loading;
    }
    if (emptyEl) {
        emptyEl.hidden = !empty;
    }
    if (errorEl) {
        errorEl.hidden = !error;
        if (!error) {
            errorEl.textContent = '';
        }
    }
    if (listEl) {
        listEl.hidden = !list;
        if (!list) {
            listEl.replaceChildren();
        }
    }
}

function normalizeDocuments(data) {
    if (Array.isArray(data)) {
        return data;
    }
    if (data && Array.isArray(data.documents)) {
        return data.documents;
    }
    return [];
}

function renderDocumentsList(documents, listEl, actorId) {
    if (!documents.length) {
        const emptyEl = document.getElementById('documents-empty');
        if (emptyEl) {
            emptyEl.querySelector('.cv-empty-title').textContent = 'No documents on file';
            emptyEl.querySelector('.cv-empty-hint').textContent = 'Upload a resume or cover letter above to get started.';
        }
        showDocumentsState({ empty: true });
        return;
    }

    listEl.replaceChildren();
    documents.forEach(documentItem => {
        listEl.appendChild(buildDocumentCard(documentItem, actorId));
    });
    showDocumentsState({ list: true });
}

function buildDocumentCard(documentItem, actorId) {
    const fileName = documentItem.fileName || 'document';
    const parseTimestamp = documentItem.parseTimestamp
        ? new Date(documentItem.parseTimestamp).toLocaleString(undefined, {
            day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
        })
        : '—';
    const sizeLabel = formatDocumentSize(documentItem.documentSize);
    const documentId = documentItem.documentId || '';
    const excerpt = truncateExtractedText(documentItem.extractedText);
    const typeLabel = documentTypeLabel(documentItem.documentType || '', fileName);

    const card = cloneTemplate('cv-doc-card-template');
    const badge = card.querySelector('[data-field="badge"]');
    badge.textContent = typeLabel;
    badge.setAttribute('data-type', typeLabel);

    const nameEl = card.querySelector('[data-field="name"]');
    nameEl.textContent = fileName;
    nameEl.title = fileName;

    card.querySelector('[data-field="size"]').textContent = sizeLabel;
    card.querySelector('[data-field="parsed"]').textContent = `Parsed ${parseTimestamp}`;

    const previewToggle = card.querySelector('[data-field="preview-toggle"]');
    const preview = card.querySelector('[data-field="preview"]');
    const previewText = card.querySelector('[data-field="preview-text"]');
    if (excerpt) {
        previewToggle.hidden = false;
        previewText.textContent = excerpt;
        previewToggle.addEventListener('click', () => {
            const expanded = previewToggle.getAttribute('aria-expanded') === 'true';
            previewToggle.setAttribute('aria-expanded', expanded ? 'false' : 'true');
            previewToggle.textContent = expanded ? 'Show preview' : 'Hide preview';
            preview.hidden = expanded;
        });
    }

    const downloadBtn = card.querySelector('[data-field="download"]');
    const deleteBtn = card.querySelector('[data-field="delete"]');
    if (documentId) {
        downloadBtn.hidden = false;
        downloadBtn.setAttribute('data-document-id', documentId);
        downloadBtn.setAttribute('aria-label', `Download ${fileName}`);
        downloadBtn.addEventListener('click', () => downloadDocument(downloadBtn, documentId, actorId));

        deleteBtn.hidden = false;
        deleteBtn.setAttribute('data-document-id', documentId);
        deleteBtn.setAttribute('aria-label', `Delete ${fileName}`);
        deleteBtn.addEventListener('click', () => deleteDocument(deleteBtn, documentId, actorId, fileName));
    }

    return card;
}

function documentTypeLabel(documentType, fileName) {
    const mime = (documentType || '').toLowerCase();
    if (mime.includes('pdf')) {
        return 'PDF';
    }
    if (mime.includes('word') || mime.includes('officedocument')) {
        return 'DOC';
    }
    if (mime.includes('text')) {
        return 'TXT';
    }
    const extension = String(fileName).split('.').pop();
    return extension ? extension.toUpperCase().slice(0, 4) : 'FILE';
}

function formatDocumentSize(documentSize) {
    if (documentSize === null || documentSize === undefined) {
        return '—';
    }
    if (documentSize < 1024) {
        return `${documentSize} B`;
    }
    if (documentSize < 1024 * 1024) {
        return `${(documentSize / 1024).toFixed(1)} KB`;
    }
    return `${(documentSize / (1024 * 1024)).toFixed(1)} MB`;
}

function truncateExtractedText(extractedText) {
    if (!extractedText) {
        return '';
    }
    const normalized = String(extractedText).trim();
    if (normalized.length <= 480) {
        return normalized;
    }
    return `${normalized.substring(0, 480)}…`;
}

async function downloadDocument(button, documentId, actorId) {
    button.disabled = true;
    button.classList.add('is-busy');
    try {
        const path = `/documents/${encodeURIComponent(documentId)}/link?actorId=${encodeURIComponent(actorId)}`;
        const response = await ApiClient.post(path, {});
        const url = response.data && response.data.url;
        if (!url) {
            throw new Error('Download link missing from response');
        }
        window.open(url, '_blank', 'noopener,noreferrer');
    } catch (error) {
        console.error('Download failed:', error);
        const message = error instanceof ApiError ? error.getMessage() : error.message;
        await showCvModal({
            title: 'Download failed',
            message,
            confirmLabel: 'OK'
        });
    } finally {
        button.disabled = false;
        button.classList.remove('is-busy');
    }
}

async function deleteDocument(button, documentId, actorId, fileName) {
    const confirmed = await showCvModal({
        title: 'Delete document',
        message: `Delete "${fileName}"? This cannot be undone.`,
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        danger: true
    });
    if (!confirmed) {
        return;
    }

    button.disabled = true;
    button.classList.add('is-busy');
    try {
        const path = `/documents/${encodeURIComponent(documentId)}?actorId=${encodeURIComponent(actorId)}`;
        await ApiClient.delete(path);
        await refreshDocumentsList();
    } catch (error) {
        console.error('Delete failed:', error);
        const message = error instanceof ApiError ? error.getMessage() : error.message;
        await showCvModal({
            title: 'Delete failed',
            message,
            confirmLabel: 'OK'
        });
        button.disabled = false;
        button.classList.remove('is-busy');
    }
}

/**
 * Shows the profile modal. Returns true when the confirm action is chosen.
 */
function showCvModal({ title, message, confirmLabel = 'OK', cancelLabel = null, danger = false }) {
    const dialog = document.getElementById('cv-modal');
    const titleEl = document.getElementById('cv-modal-title');
    const messageEl = document.getElementById('cv-modal-message');
    const cancelBtn = document.getElementById('cv-modal-cancel');
    const confirmBtn = document.getElementById('cv-modal-confirm');

    titleEl.textContent = title;
    messageEl.textContent = message;
    confirmBtn.textContent = confirmLabel;
    confirmBtn.classList.toggle('is-danger', Boolean(danger));

    if (cancelLabel) {
        cancelBtn.hidden = false;
        cancelBtn.textContent = cancelLabel;
    } else {
        cancelBtn.hidden = true;
    }

    return new Promise(resolve => {
        const onClose = () => {
            dialog.removeEventListener('close', onClose);
            resolve(dialog.returnValue === 'confirm');
        };
        dialog.addEventListener('close', onClose);
        dialog.showModal();
        confirmBtn.focus();
    });
}

async function uploadResumeDocuments() {
    const statusDiv = document.getElementById('resume-upload-status');
    const uploadBtn = document.getElementById('resume-upload-btn');
    const dropzone = document.getElementById('resume-upload-box');
    const actorId = AuthUtils.getCandidateId();
    const files = pendingResumeFiles.slice();

    if (files.length === 0) {
        setUploadStatus(statusDiv, 'Select at least one file to upload.', 'error');
        return;
    }
    if (!actorId) {
        setUploadStatus(statusDiv, 'Unable to resolve actor id.', 'error');
        return;
    }

    const formData = new FormData();
    formData.append('actorId', actorId);
    files.forEach(file => formData.append('documents', file));

    if (uploadBtn) {
        uploadBtn.disabled = true;
    }
    if (dropzone) {
        dropzone.classList.add('is-uploading');
    }
    const busyLabel = files.length === 1 ? 'Uploading and parsing…' : `Uploading and parsing ${files.length} files…`;
    setUploadStatus(statusDiv, busyLabel, 'busy');

    try {
        const response = await ApiClient.postMultipart('/documents', formData);
        const summary = summarizeUploadResults(response.data, files.length);
        setUploadStatus(statusDiv, summary.message, summary.tone);
        setPendingResumeFiles([]);
        await refreshDocumentsList();
    } catch (error) {
        console.error('Upload failed:', error);
        const message = error instanceof ApiError ? error.getMessage() : error.message;
        setUploadStatus(statusDiv, 'Upload failed: ' + message, 'error');
        if (uploadBtn && pendingResumeFiles.length > 0) {
            uploadBtn.disabled = false;
            uploadBtn.textContent = pendingResumeFiles.length === 1 ? 'Upload' : `Upload ${pendingResumeFiles.length}`;
        }
    } finally {
        if (dropzone) {
            dropzone.classList.remove('is-uploading');
        }
    }
}

function summarizeUploadResults(data, requestedCount) {
    const results = Array.isArray(data) ? data : [];
    const failures = results.filter(result => result && result.error);
    const successCount = Math.max(results.length - failures.length, 0);

    if (failures.length === 0) {
        const message = requestedCount === 1 ? 'Upload complete.' : `Uploaded ${successCount} files.`;
        return { message, tone: 'success' };
    }

    const failureNames = failures
        .map(result => result.fileName || 'file')
        .join(', ');
    if (successCount === 0) {
        return { message: `Upload failed: ${failureNames}`, tone: 'error' };
    }
    return {
        message: `Uploaded ${successCount} of ${results.length}. Failed: ${failureNames}`,
        tone: 'error'
    };
}

function setUploadStatus(statusDiv, message, tone) {
    if (!statusDiv) {
        return;
    }
    statusDiv.textContent = message;
    statusDiv.className = 'cv-upload-status';
    if (tone) {
        statusDiv.classList.add(`is-${tone}`);
    }
}
