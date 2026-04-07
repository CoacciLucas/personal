import { desktopCapturer, nativeImage } from 'electron'

export class ScreenshotService {
  async captureScreen(): Promise<string> {
    const sources = await desktopCapturer.getSources({
      types: ['screen'],
      thumbnailSize: { width: 1920, height: 1080 }
    })

    if (sources.length === 0) {
      throw new Error('Nenhuma tela encontrada')
    }

    const primary = sources[0]
    const thumbnail = primary.thumbnail
    const originalSize = thumbnail.getSize()

    // Resize to max 800px width for faster API processing
    const maxWidth = 800
    let width = originalSize.width
    let height = originalSize.height

    if (width > maxWidth) {
      const ratio = maxWidth / width
      width = maxWidth
      height = Math.round(height * ratio)
    }

    const resized = thumbnail.resize({ width, height })

    // JPEG with quality ~50% for smaller payload
    return resized.toJPEG(50).toString('base64')
  }
}
