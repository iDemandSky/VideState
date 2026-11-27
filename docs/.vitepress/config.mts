import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "VideState",
  description: "A Roblox Vide source state handler.",
  base: '/VideState/',
  head: [['link', { rel: 'icon', type: 'image/svg+xml', href: '/VideState/favicon.svg' }]],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    logo: { light: '/logo-light.svg', dark: '/logo-dark.svg' },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'About', link: '/introduction/about' },
      { text: 'Guide', link: '/guide/getting-started' }
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'About', link: '/introduction/about' },
          { text: 'Why VideState', link: '/introduction/why' }
        ]
      },
      {
        text: 'Guide',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Schemas', link: '/guide/schemas' },
          { text: 'Rules', link: '/guide/rules' },
          { text: 'Handlers', link: '/guide/handlers' },
          { text: 'Transitions', link: '/guide/transitions' },
          { text: 'Every handler', link: '/guide/every-handler' },
          { text: 'Info (debugging)', link: '/guide/info' },
          { text: 'Debug view', link: '/guide/debug' }
        ]
      },
      {
        text: 'Examples',
        items: [
          { text: 'Components', link: '/examples/components' },
          { text: 'Inheritance', link: '/examples/inheritance' },
          { text: 'Tween config', link: '/examples/tween-config' }
        ]
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/iDemandSky/VideState' }
    ]
  }
})
