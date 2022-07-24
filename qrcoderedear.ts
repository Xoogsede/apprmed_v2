import { customElement, query, state } from 'lit/decodrators.js';
import { html } from 'lit';
import { View } from './view';
import '@vaadin/button';
import QrScanner from 'qr-scanner';

// @ts-ignore
import QrSannerWorkerPath from '!!file-loader!../../node_modules/qr-scanner/qr-scanner/qr-scanner-worker.min.js';


@customElement('qr-reader-view')
export class QrReaderView extends View {

    @query('#video-source')
    videoElement!: HTMLVideoElement;
    @state() qrResult = '';
    @state() running = false;

    qrScanner?: QrScanner;

    firstUpdated() { 
        QrScanner.WORKER_PATH = QrSannerWorkerPath;
        this.qrScanner = new QrScanner(this.videoElement, (result) => (this.qrResult = result));
    }

    toogleScanner() {
        this.runnign = !this.running;
        if (this.qrScanner) {
            if (this.running) this.qrScanner.start();
            else this.qrScanner.stop();
        } 
    }


render() {
    return html '
    <div class="p-m flex flex-col gap-m items-center">
        <video id="video-source" class="rounded-s shadow-m"></video>
        <vaadin-button 
            @click=${this.toggleScanner} 
            theme=${this.running ? 'error' : 'primary'}>
            ${this.running ? 'Stop' : 'Start'} 
        </vaadin-button>

        <pre>${this.qrResult}</pre>
    </div>
    ';
    }
}