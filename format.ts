type EndLink = {
  display: string;
  link: string;
};

// blob?
type Attachment = string;

type Media = string;

type CoreMessage = {
  sender: "user" | "assistant";
  timestamp: number;
  message: string;
  start_media?: Media;
  end_media?: Array<Media>;
  end_links?: EndLink;
  attachments?: Array<Attachment>;
};

type SearchResult = {
  display: string;
  link: string;
};

type SearchResultMessage = CoreMessage & {
  results: Array<SearchResult>;
};

// arbitrary html injected by the LLM at the end of the message
type CardMessage = CoreMessage & {
  card: string;
};

type Message = CoreMessage | SearchResultMessage | CardMessage;

type Conversation = {
  uuid: string;
  title: string;
  messages: Array<Message>;
};
