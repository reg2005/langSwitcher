export default defineAppConfig({
  header: {
    title: 'LangSwitcher',
  },
  seo: {
    title: 'LangSwitcher — Keyboard Layout Converter for macOS',
    description: 'Free, open-source keyboard layout text converter for macOS. Press a hotkey, get mistyped text converted instantly.',
  },
  socials: {
    github: 'https://github.com/reg2005/langSwitcher',
  },
  github: {
    url: 'https://github.com/reg2005/langSwitcher',
    branch: 'main',
    rootDir: 'docs',
  },
  toc: {
    bottom: {
      title: 'Community',
      links: [{
        icon: 'i-lucide-bug',
        label: 'Report a Bug',
        to: 'https://github.com/reg2005/langSwitcher/issues',
        target: '_blank',
      }, {
        icon: 'i-lucide-heart',
        label: 'Contribute',
        to: 'https://github.com/reg2005/langSwitcher',
        target: '_blank',
      }],
    },
  },
})
