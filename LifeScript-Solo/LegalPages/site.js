(function () {
  const siteData = window.lifeScriptSoloLegalPages;
  if (!siteData) return;

  const storageKey = "lifescript-solo-legal-language";
  const supportedCodes = siteData.languages.map((item) => item.code);
  const page = document.body.dataset.page || "home";

  function normalizeLanguage(input) {
    if (!input) return null;
    const lowered = input.toLowerCase();

    if (lowered.startsWith("zh")) return "zh-Hans";
    if (lowered.startsWith("en")) return "en";
    if (lowered.startsWith("ja")) return "ja";
    if (lowered.startsWith("ko")) return "ko";

    return supportedCodes.includes(input) ? input : null;
  }

  function resolveLanguage() {
    const params = new URLSearchParams(window.location.search);
    const fromQuery = normalizeLanguage(params.get("lang"));
    if (fromQuery) return fromQuery;

    const fromStorage = normalizeLanguage(window.localStorage.getItem(storageKey));
    if (fromStorage) return fromStorage;

    const fromBrowser = normalizeLanguage(navigator.language || "");
    return fromBrowser || "zh-Hans";
  }

  function withLanguage(path, language) {
    const url = new URL(path, window.location.href);
    url.searchParams.set("lang", language);
    return `${url.pathname.split("/").pop()}?${url.searchParams.toString()}`;
  }

  function isExternalHref(href) {
    return /^(mailto:|https?:|tel:)/i.test(href);
  }

  function localizedHref(href, language) {
    return isExternalHref(href) ? href : withLanguage(href, language);
  }

  function renderAction(action, language) {
    return `
      <a class="cta-link ${action.variant === "primary" ? "primary" : "secondary"}" href="${localizedHref(action.href, language)}">
        ${action.label}
      </a>
    `;
  }

  function renderLinks(links, language) {
    if (!links || !links.length) return "";
    return `
      <div class="meta-row">
        ${links.map((link) => `<a class="inline-link" href="${localizedHref(link.href, language)}">${link.label}</a>`).join("")}
      </div>
    `;
  }

  function renderCards(cards, language) {
    return cards.map((card) => `
      <article class="highlight-${card.accent}">
        <p class="section-kicker">${card.kicker}</p>
        <h2>${card.title}</h2>
        <p>${card.body}</p>
        ${card.href ? `<div class="meta-row"><a class="inline-link" href="${withLanguage(card.href, language)}">${card.title}</a></div>` : ""}
      </article>
    `).join("");
  }

  function renderSections(sections, language) {
    return sections.map((section) => `
      <article class="section-card highlight-${section.accent}">
        <p class="section-kicker">${section.kicker}</p>
        <h2>${section.title}</h2>
        <p>${section.body}</p>
        ${section.bullets && section.bullets.length ? `<ul>${section.bullets.map((bullet) => `<li>${bullet}</li>`).join("")}</ul>` : ""}
        ${renderLinks(section.links, language)}
      </article>
    `).join("");
  }

  function renderLanguageSwitcher(language, translation) {
    return `
      <div class="language-switcher" role="group" aria-label="${translation.languageLabel}">
        ${siteData.languages.map((item) => `
          <button
            type="button"
            class="chip-button"
            data-language="${item.code}"
            aria-pressed="${item.code === language ? "true" : "false"}"
          >
            ${item.label}
          </button>
        `).join("")}
      </div>
    `;
  }

  function renderNavigation(translation, language) {
    const items = [
      ["home", "index.html"],
      ["privacy", "privacy.html"],
      ["support", "support.html"],
      ["contact", "contact.html"],
      ["contentRating", "content-rating.html"],
      ["terms", "terms.html"]
    ];

    return items.map(([key, href]) => `
      <a class="nav-link ${page === key ? "active" : ""}" href="${withLanguage(href, language)}">
        ${translation.nav[key]}
      </a>
    `).join("");
  }

  function renderDocument(translation, language) {
    const currentPage = translation.pages[page];
    const contentClass = page === "home" ? "content-grid" : "legal-grid";
    const sectionContent = page === "home"
      ? renderCards(currentPage.cards, language)
      : renderSections(currentPage.sections, language);

    document.documentElement.lang = language;
    document.title = currentPage.title === translation.brandTitle
      ? currentPage.title
      : `${currentPage.title} · ${translation.brandTitle}`;

    const descriptionTag = document.querySelector('meta[name="description"]');
    if (descriptionTag) descriptionTag.setAttribute("content", currentPage.description);

    const container = document.getElementById("app");
    container.innerHTML = `
      <div class="page-frame">
        <header class="topbar">
          <div class="brand-block">
            <div class="brand-mark">天</div>
            <div class="brand-copy">
              <p class="eyebrow">${translation.brandEyebrow}</p>
              <p class="brand-title">${translation.brandTitle}</p>
            </div>
          </div>
          <div class="toolbar">
            ${renderLanguageSwitcher(language, translation)}
            <nav class="nav-links" aria-label="${translation.navigationLabel || translation.languageLabel}">
              ${renderNavigation(translation, language)}
            </nav>
          </div>
        </header>

        <section class="hero">
          <div class="hero-grid">
            <div class="hero-copy">
              <div>
                <p class="eyebrow">${currentPage.heroKicker}</p>
                <h1 class="hero-title">${currentPage.heroTitle}</h1>
              </div>
              <p class="hero-summary">${currentPage.heroSummary}</p>
              <div class="hero-strip">
                ${currentPage.heroTags.map((tag) => `<span>${tag}</span>`).join("")}
              </div>
              <div class="hero-actions">
                ${(currentPage.heroActions || []).map((action) => renderAction(action, language)).join("")}
              </div>
            </div>

            <aside class="hero-note">
              <p class="note-title">${currentPage.noteTitle}</p>
              <p class="note-copy">${currentPage.noteBody}</p>
              <div class="hero-strip">
                <span>${translation.common.appReviewReady}</span>
                <span>${translation.common.userFacing}</span>
                <span>${translation.common.multiLanguage}</span>
              </div>
              <p class="note-copy">${translation.common.lastUpdated}</p>
            </aside>
          </div>
        </section>

        <section class="${contentClass}">
          ${sectionContent}
        </section>

        <footer class="footer">
          <p class="note-title">${translation.footerTitle}</p>
          <p>${translation.footerBody}</p>
          <p>${translation.common.languageNotice}</p>
        </footer>
      </div>
    `;

    container.querySelectorAll("[data-language]").forEach((button) => {
      button.addEventListener("click", () => {
        const nextLanguage = button.getAttribute("data-language");
        if (!nextLanguage || nextLanguage === language) return;

        window.localStorage.setItem(storageKey, nextLanguage);
        const nextUrl = new URL(window.location.href);
        nextUrl.searchParams.set("lang", nextLanguage);
        window.history.replaceState({}, "", nextUrl.toString());

        const nextTranslation = siteData.translations[nextLanguage] || siteData.translations["zh-Hans"];
        renderDocument(nextTranslation, nextLanguage);
      });
    });
  }

  const language = resolveLanguage();
  const translation = siteData.translations[language] || siteData.translations["zh-Hans"];
  renderDocument(translation, language);
})();
