export default defineNuxtConfig({
  modules: ['@nuxtjs/i18n'],
  i18n: {
    defaultLocale: 'en',
    locales: [
      { code: 'en', name: 'English' },
      { code: 'ru', name: 'Русский' },
    ],
  },
  site: {
    name: 'LangSwitcher',
    url: 'https://reg2005.github.io/langSwitcher',
  },
  app: {
    baseURL: '/langSwitcher/',
  },
})
