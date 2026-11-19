import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "VideState",
  description: "A Roblox Vide source state handler.",
  base: '/VideState/',
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Introduction', link: '/introduction' },
      { text: 'Guide', link: '/guide/getting-started' }
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
          { text: 'Schemas', link: '/guide/rule-and-schemas' },
          { text: 'Rules and handlers', link: '/guide/rules-and-handlers' },
          { text: 'Transitions', link: '/guide/transitions' }
        ]
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/iDemandSky/VideState' }
    ]
  }
})
