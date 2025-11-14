const container = document.getElementById('notepad');
const textarea = document.getElementById('notepad-input');
const view = document.getElementById('notepad-view');
const saveButton = document.getElementById('notepad-save');
const cancelButton = document.getElementById('notepad-cancel');
const closeButton = document.getElementById('notepad-close');
const authorLabel = document.getElementById('notepad-author');
const dateLabel = document.getElementById('notepad-date');

let mode = 'write';

function setHidden(element, shouldHide) {
    if (shouldHide) {
        element.classList.add('hidden');
    } else {
        element.classList.remove('hidden');
    }
}

function openNotepad(payload) {
    mode = payload.mode === 'read' ? 'read' : 'write';

    container.classList.remove('hidden');
    document.body.classList.add('notepad-open');

    const text = payload.text || '';
    textarea.value = text;
    view.textContent = text;

    const hasAuthor = payload.author && payload.author.trim() !== '';
    authorLabel.textContent = hasAuthor ? `Author: ${payload.author}` : '';

    if (payload.created) {
        const date = new Date(payload.created * 1000);
        if (!Number.isNaN(date.getTime())) {
            dateLabel.textContent = `Written: ${date.toLocaleString()}`;
        } else {
            dateLabel.textContent = '';
        }
    } else {
        dateLabel.textContent = '';
    }

    if (mode === 'write') {
        setHidden(textarea, false);
        setHidden(view, true);
        saveButton.textContent = 'Save Note';
        saveButton.classList.remove('hidden');
        cancelButton.textContent = 'Cancel';
        textarea.focus();
        textarea.setSelectionRange(text.length, text.length);
    } else {
        setHidden(textarea, true);
        setHidden(view, false);
        saveButton.classList.add('hidden');
        cancelButton.textContent = 'Close';
    }
}

function closeNotepad(triggerCancel = false) {
    container.classList.add('hidden');
    document.body.classList.remove('notepad-open');

    if (triggerCancel) {
        fetch(`https://mythic-notepad/Notepad:Close`, {
            method: 'POST',
            body: JSON.stringify({})
        });
    }
}

function submitNote() {
    const text = textarea.value || '';

    fetch(`https://mythic-notepad/Notepad:Submit`, {
        method: 'POST',
        body: JSON.stringify({ text })
    });
}

window.addEventListener('message', (event) => {
    if (!event.data || event.data.action !== 'NOTEPAD_OPEN') {
        return;
    }

    openNotepad(event.data.data || {});
});

saveButton.addEventListener('click', (event) => {
    event.preventDefault();
    if (mode === 'write') {
        submitNote();
    }
});

cancelButton.addEventListener('click', (event) => {
    event.preventDefault();
    closeNotepad(true);
});

closeButton.addEventListener('click', (event) => {
    event.preventDefault();
    closeNotepad(true);
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        closeNotepad(true);
    }

    if (mode === 'write' && event.ctrlKey && event.key.toLowerCase() === 's') {
        event.preventDefault();
        submitNote();
    }
});

window.addEventListener('focus', () => {
    if (!container.classList.contains('hidden') && mode === 'write') {
        textarea.focus();
    }
});

window.addEventListener('message', (event) => {
    if (!event.data) {
        return;
    }

    if (event.data.action === 'NOTEPAD_CLOSE') {
        container.classList.add('hidden');
        document.body.classList.remove('notepad-open');
    }
});