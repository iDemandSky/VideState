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
          { text: 'Why VideState', link: '/introduction/why' },
          { text: 'Performance', link: '/introduction/performance' }
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
          { text: 'Info', link: '/guide/info' },
          { text: 'Debug view', link: '/guide/debug' },
          { text: 'Testing', link: '/guide/testing' }
        ]
      },
      {
        text: 'Migration',
        items: [
          { text: 'Migrating to 0.5.0', link: '/migration/to-0-5-0' },
          { text: 'Migrating to 0.4.0', link: '/migration/to-0-4-0' },
          { text: 'Migrating to 0.3.0', link: '/migration/to-0-3-0' }
        ]
      },
      {
        text: 'Examples',
        items: [
          { text: 'Components', link: '/examples/components' },
          { text: 'Inheritance', link: '/examples/inheritance' },
          { text: 'Tween Configuration', link: '/examples/tween-config' }
        ]
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/iDemandSky/VideState' }
    ]
  }
})
