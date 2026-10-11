import type { SendMessage } from '@/app/project/[id]/_hooks/use-chat';
import { OPENROUTER_MODELS, type ChatType } from '@onlook/models';
import { makeAutoObservable } from 'mobx';
import type { EditorEngine } from '../engine';
import { ChatContext } from './context';
import { ConversationManager } from './conversation';

export const FOCUS_CHAT_INPUT_EVENT = 'focus-chat-input';
export class ChatManager {
    conversation: ConversationManager;
    context: ChatContext;

    // Content sent from useChat hook
    _sendMessageAction: SendMessage | null = null;
    isStreaming = false;
    selectedModel: string = OPENROUTER_MODELS.CLAUDE_4_5_SONNET;

    constructor(private editorEngine: EditorEngine) {
        this.context = new ChatContext(this.editorEngine);
        this.conversation = new ConversationManager(this.editorEngine);
        makeAutoObservable(this);
    }

    init() {
        try {
            const savedModel = localStorage.getItem('onlook-chat-model');
            if (savedModel && savedModel.length <= 200 && /^[a-zA-Z0-9._-]+\/[a-zA-Z0-9._:/-]+$/.test(savedModel)) {
                this.selectedModel = savedModel;
            }
        } catch {
            // Storage may be disabled in the browser.
        }
        this.context.init();
    }

    setSelectedModel(model: string) {
        this.selectedModel = model;
        try {
            localStorage.setItem('onlook-chat-model', model);
        } catch {
            // The current session still uses the selected model.
        }
    }

    focusChatInput() {
        window.dispatchEvent(new Event(FOCUS_CHAT_INPUT_EVENT));
    }

    getCurrentConversationId() {
        return this.conversation.current?.id;
    }

    setIsStreaming(isStreaming: boolean) {
        this.isStreaming = isStreaming;
    }

    setChatActions(sendMessage: SendMessage) {
        this._sendMessageAction = sendMessage;
    }

    async sendMessage(content: string, type: ChatType): Promise<void> {
        if (!this._sendMessageAction) {
            throw new Error('Chat actions not initialized');
        }

        await this._sendMessageAction(content, type);
    }

    clear() {
        this.context.clear();
        this.conversation.clear();
    }
}
