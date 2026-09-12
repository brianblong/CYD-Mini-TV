"use strict";
const playlistData = document.querySelector("#playlist-data");
if (playlistData) {
  let catalogue = JSON.parse(playlistData.textContent);
  let index = 0, paused = false, sequence = 0;
  let slide = document.querySelector("#slide");
  const empty = document.querySelector("#empty-screen");
  const counter = document.querySelector("#counter");
  const status = document.querySelector("#slide-status");
  const controls = ["previous", "pause", "next"].map(id => document.getElementById(id));
  function updateControls() {
    controls.forEach(button => { button.disabled = catalogue.photos.length < 2; });
  }
  function show(nextIndex) {
    const ticket = ++sequence;
    updateControls();
    if (!catalogue.photos.length) {
      if (slide) slide.hidden = true;
      empty.hidden = false;
      counter.textContent = "00 / 00";
      return;
    }
    index = (nextIndex + catalogue.photos.length) % catalogue.photos.length;
    const photo = catalogue.photos[index];
    const loaded = new Image();
    loaded.onload = () => {
      if (ticket !== sequence) return;
      if (!slide) { slide = document.createElement("img"); slide.id = "slide"; empty.before(slide); }
      slide.src = loaded.src;
      slide.alt = photo.name;
      slide.hidden = false;
      empty.hidden = true;
      counter.textContent = `${String(index + 1).padStart(2, "0")} / ${String(catalogue.photos.length).padStart(2, "0")}`;
      status.textContent = "";
    };
    loaded.onerror = () => { if (ticket === sequence) status.textContent = "This picture could not load. We’ll try the next one."; };
    loaded.src = `/admin/photos/${photo.id}.png`;
  }
  document.querySelector("#previous").onclick = () => show(index - 1);
  document.querySelector("#next").onclick = () => show(index + 1);
  document.querySelector("#pause").onclick = event => {
    paused = !paused;
    event.currentTarget.textContent = paused ? "▶" : "Ⅱ";
    event.currentTarget.setAttribute("aria-label", paused ? "Play slideshow" : "Pause slideshow");
    event.currentTarget.setAttribute("aria-pressed", String(paused));
  };
  setInterval(() => { if (!paused && !document.hidden && catalogue.photos.length > 1) show(index + 1); }, 5000);
  let polling = false;
  async function refresh() {
    if (polling || document.hidden) return;
    polling = true;
    try {
      const response = await fetch("/admin/playlist", { cache: "no-store" });
      if (response.redirected) { location.assign("/admin/"); return; }
      if (!response.ok) throw new Error("Playlist unavailable");
      const next = await response.json();
      if (next.revision !== catalogue.revision) {
        const currentId = catalogue.photos[index]?.id;
        catalogue = next;
        show(Math.max(0, catalogue.photos.findIndex(photo => photo.id === currentId)));
      }
    } catch (_) { status.textContent = "Connection interrupted. Keeping the current show while we reconnect."; }
    finally { polling = false; }
  }
  setInterval(refresh, 15000);
  document.addEventListener("visibilitychange", () => { if (!document.hidden) refresh(); });
  updateControls();
}

const grid = document.querySelector("#photo-grid");
let orderDirty = false;
let submitting = false;
let uploading = false;
let catalogueStale = false;
if (grid) {
  const save = document.querySelector("#save-order");
  const originalOrder = [...grid.querySelectorAll(".photo-card")].map(card => card.dataset.id).join(",");
  function updateOrder() {
    const cards = [...grid.querySelectorAll(".photo-card")];
    const inputs = document.querySelector("#order-inputs");
    inputs.replaceChildren();
    cards.forEach((card, index) => {
      card.querySelector(".photo-number").textContent = String(index + 1).padStart(2, "0");
      card.querySelector('[data-move="-1"]').disabled = index === 0;
      card.querySelector('[data-move="1"]').disabled = index === cards.length - 1;
      const input = document.createElement("input");
      input.type = "hidden"; input.name = "order"; input.value = card.dataset.id; inputs.append(input);
    });
    orderDirty = cards.map(card => card.dataset.id).join(",") !== originalOrder;
    save.disabled = !orderDirty;
    save.textContent = orderDirty ? "Save order" : "Order saved";
    document.querySelector("#order-status").textContent = orderDirty ? "Your new order is ready. Select Save order to update the show." : "";
  }
  grid.addEventListener("click", event => {
    if (catalogueStale) return;
    const button = event.target.closest("[data-move]");
    if (!button) return;
    const card = button.closest(".photo-card");
    if (button.dataset.move === "-1" && card.previousElementSibling) card.previousElementSibling.before(card);
    else if (button.dataset.move === "1" && card.nextElementSibling) card.nextElementSibling.after(card);
    updateOrder();
    if (button.disabled) card.querySelector("[data-move]:not(:disabled)")?.focus();
    else button.focus();
  });
  let dragging;
  grid.addEventListener("dragstart", event => {
    if (catalogueStale) { event.preventDefault(); return; }
    dragging = event.target.closest(".photo-card");
    if (!dragging) return;
    event.dataTransfer.setData("text/plain", dragging.dataset.id);
    event.dataTransfer.effectAllowed = "move";
    dragging.classList.add("dragging");
  });
  grid.addEventListener("dragover", event => {
    const target = event.target.closest(".photo-card");
    if (!dragging || !target || target === dragging) return;
    event.preventDefault();
    grid.querySelectorAll(".drop-target").forEach(card => card.classList.remove("drop-target"));
    target.classList.add("drop-target");
  });
  grid.addEventListener("drop", event => {
    const target = event.target.closest(".photo-card");
    if (!dragging || !target || target === dragging) return;
    event.preventDefault();
    const cards = [...grid.children];
    if (cards.indexOf(dragging) < cards.indexOf(target)) target.after(dragging);
    else target.before(dragging);
    updateOrder();
  });
  grid.addEventListener("dragend", () => {
    grid.querySelectorAll(".dragging,.drop-target").forEach(card => card.classList.remove("dragging", "drop-target"));
    dragging = null;
  });
  document.querySelector("#order-form").addEventListener("submit", event => { if (catalogueStale) { event.preventDefault(); return; } submitting = true; save.disabled = true; save.textContent = "Saving…"; });
  document.querySelectorAll(".delete-form").forEach(form => form.addEventListener("submit", event => {
    const suffix = orderDirty ? " Your unsaved order changes will also be discarded." : "";
    if (!confirm(`Delete “${form.dataset.name}” from the catalogue and slideshow?${suffix}`)) event.preventDefault();
    else submitting = true;
  }));
  window.addEventListener("beforeunload", event => { if (uploading || (orderDirty && !submitting)) { event.preventDefault(); event.returnValue = ""; } });
}

const uploadForm = document.querySelector("#upload-form");
if (uploadForm) {
  const photoInput = document.querySelector("#photo");
  const folder = document.querySelector("#folder");
  const folderButton = document.querySelector("#choose-folder");
  const selection = document.querySelector("#selection-summary");
  const status = document.querySelector("#upload-status");
  const errors = document.querySelector("#upload-errors");
  const meter = document.querySelector("#upload-meter");
  let selectedFiles = [];
  let skipped = 0;
  let incomplete = [];
  document.querySelector("#folder-controls").hidden = false;
  folderButton.hidden = !("webkitdirectory" in folder);
  function select(files) {
    const incoming = [...files];
    selectedFiles = incoming.filter(file => /\.(jpe?g|png|webp)$/i.test(file.name));
    skipped = incoming.length - selectedFiles.length;
    incomplete = [];
    photoInput.required = !selectedFiles.length;
    selection.textContent = `${selectedFiles.length} picture(s) selected${skipped ? ` · ${skipped} unsupported file(s) skipped` : ""}.`;
    const submit = uploadForm.querySelector('[type="submit"]');
    submit.textContent = "Add to our show ＋";
    submit.disabled = false;
  }
  photoInput.addEventListener("change", () => { folder.value = ""; select(photoInput.files); });
  folderButton.onclick = () => folder.click();
  folder.addEventListener("change", () => { photoInput.value = ""; select([...folder.files].sort((a, b) => a.webkitRelativePath.localeCompare(b.webkitRelativePath, undefined, { numeric: true }))); });
  uploadForm.addEventListener("submit", async event => {
    event.preventDefault();
    if (uploading) return;
    if (orderDirty && !confirm("Adding pictures will discard your unsaved order changes. Continue?")) return;
    if (!selectedFiles.length && !incomplete.length) { selection.textContent = "Choose JPG, PNG, or WebP pictures first."; return; }
    const queue = incomplete.length ? incomplete : selectedFiles.map(file => ({ file, id: crypto.randomUUID().replaceAll("-", "") }));
    incomplete = [];
    errors.replaceChildren();
    document.querySelector("#upload-progress").hidden = false;
    document.querySelector("#review-uploads").hidden = true;
    uploading = true;
    catalogueStale = true;
    submitting = true;
    const buttons = uploadForm.querySelectorAll("button,input[type=file]");
    buttons.forEach(control => { control.disabled = true; });
    // Prevent saves/deletes using the pre-upload catalogue revision.
    document.querySelectorAll("#save-order,.photo-actions button").forEach(control => { control.disabled = true; });
    meter.max = queue.length;
    meter.value = 0;
    let successes = 0;
    for (const item of queue) {
      status.textContent = `Uploading ${meter.value + 1} of ${queue.length}: ${item.file.name}`;
      let error = "";
      if (item.file.size > 20 * 1024 * 1024) error = "Larger than 20 MB.";
      else {
        try {
          const body = new FormData();
          body.append("csrf", uploadForm.elements.csrf.value);
          body.append("photo", item.file, item.file.name);
          body.append("upload_id", item.id);
          const response = await fetch(uploadForm.action, { method: "POST", body, headers: { Accept: "application/json" }, signal: AbortSignal.timeout(120000) });
          if (response.redirected) throw new Error("Your session expired. Sign in again.");
          if (!(response.headers.get("content-type") || "").includes("application/json")) throw new Error("The server could not accept this picture. Try again or sign in again.");
          const result = await response.json();
          if (!response.ok) throw new Error(result.error || "Upload failed.");
          successes++;
        } catch (exception) { error = exception.message || "Connection interrupted. Try again."; }
      }
      if (error) {
        incomplete.push(item);
        const li = document.createElement("li");
        li.textContent = `${item.file.name}: ${error}`;
        errors.append(li);
      }
      meter.value++;
    }
    uploading = false;
    status.textContent = `${successes} picture(s) added. ${incomplete.length} failed.${skipped ? ` ${skipped} unsupported file(s) skipped.` : ""}`;
    document.querySelector("#review-uploads").hidden = false;
    buttons.forEach(control => { control.disabled = false; });
    photoInput.required = false;
    const submit = uploadForm.querySelector('[type="submit"]');
    submit.textContent = incomplete.length ? "Retry failed pictures" : "Pictures added";
    submit.disabled = !incomplete.length;
    orderDirty = false;
    document.querySelector("#order-status").textContent = "Open the updated catalogue before rearranging or deleting pictures.";
  });
}

const deviceIndicators = document.querySelectorAll("[data-device]");
if (deviceIndicators.length) {
  let checking = false;
  async function refreshDevices() {
    if (checking || document.hidden) return;
    checking = true;
    try {
      const response = await fetch("/admin/devices", { cache: "no-store", signal: AbortSignal.timeout(10000) });
      if (response.redirected) { location.assign("/admin/"); return; }
      if (!response.ok) throw new Error("Status unavailable");
      const { devices } = await response.json();
      devices.forEach(device => {
        const element = [...deviceIndicators].find(indicator => indicator.dataset.device === device.id);
        if (!element) return;
        element.querySelector(".status-dot").className = `status-dot ${device.online ? "online" : "offline"}`;
        element.querySelector(".device-state").textContent = device.online ? "Online" : device.last_seen ? "Offline" : "Not connected yet";
        element.title = device.last_seen ? `Last check-in: ${new Date(device.last_seen * 1000).toLocaleString()}` : "Waiting for this TV’s first check-in.";
      });
    } catch (_) {
      deviceIndicators.forEach(element => {
        element.querySelector(".status-dot").className = "status-dot unknown";
        element.querySelector(".device-state").textContent = "Status unavailable";
      });
    } finally { checking = false; }
  }
  setInterval(refreshDevices, 15000);
  document.addEventListener("visibilitychange", () => { if (!document.hidden) refreshDevices(); });
  refreshDevices();
}
