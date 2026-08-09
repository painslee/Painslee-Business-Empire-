import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Painslee Business Empire',
  description: 'PBE V1.3 Foundation',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
