export default defineNuxtConfig({
  extends: ['docus'],
  modules: ['@nuxtjs/i18n'],
  i18n: {
    defaultLocale: 'en',
    locales: [
      { code: 'en', name: 'English' },
      { code: 'ru', name: 'Русский' },
    ],
    rootRedirect: 'en',
  },
  site: {
    name: 'LangSwitcher',
    url: 'https://reg2005.github.io/langSwitcher',
  },
  app: {
    baseURL: '/langSwitcher/',
  },
  mcp: {
    enabled: false,
  },
  robots: {
    robotsTxt: false,
  },
  nitro: {
    prerender: {
      crawlLinks: true,
      routes: ['/', '/en', '/ru'],
    },
  },
})
