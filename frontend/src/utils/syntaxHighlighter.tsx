import React from 'react';
import {Prism as SyntaxHighlighter, SyntaxHighlighterProps} from 'react-syntax-highlighter';

/**
 * Type-cast SyntaxHighlighter to work with React 19.
 * This resolves type incompatibility between nested @types/react in @types/react-syntax-highlighter
 * and React 19's type definitions.
 */
export const TypedSyntaxHighlighter = SyntaxHighlighter as React.ComponentType<SyntaxHighlighterProps>;
