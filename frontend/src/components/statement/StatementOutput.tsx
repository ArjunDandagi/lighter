import React from 'react';
import {SessionStatement} from '../../client/types';
import {Prism as SyntaxHighlighter, SyntaxHighlighterProps} from 'react-syntax-highlighter';

const SyntaxHighlighterComponent = SyntaxHighlighter as React.ComponentType<SyntaxHighlighterProps>;

const StatementOutput: React.FC<{output?: SessionStatement['output']}> = ({output}) => {
  if (output?.traceback) {
    return <SyntaxHighlighterComponent>{output.traceback}</SyntaxHighlighterComponent>;
  }

  if (!output?.data) {
    return null;
  }

  const text = String(Object.values(output.data)[0]);
  if (!text) {
    return null;
  }

  return <SyntaxHighlighterComponent>{text}</SyntaxHighlighterComponent>;
};

export default StatementOutput;
