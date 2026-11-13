import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "VideState",
  description: "A Roblox Vide source state handler.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Introduction', link: '/introduction' },
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Miscellaneous', link: '/miscellaneous/development' }
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Why VideState', link: '/introduction' }
        ]
      },
      {
        text: 'Guide',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Schemas', link: '/guide/schemas' },
          { text: 'Rules and handlers', link: '/guide/rules-and-handlers' },
          { text: 'Transitions', link: '/guide/transitions' }
        ]
      },
      {
        text: 'Miscellaneous',
        items: [
          { text: 'Development', link: '/miscellaneous/development' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/vuejs/vitepress' }
    ]
  }
})
