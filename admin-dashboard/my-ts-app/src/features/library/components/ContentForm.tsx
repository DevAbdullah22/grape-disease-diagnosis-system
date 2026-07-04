import type { Dispatch, ReactNode, RefObject, SetStateAction } from 'react';

import { Bold, Italic, List, ListOrdered, Type } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import rehypeSanitize from 'rehype-sanitize';
import remarkBreaks from 'remark-breaks';
import remarkGfm from 'remark-gfm';

import { Button } from '../../../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../../../components/ui/card';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Separator } from '../../../components/ui/separator';
import { Textarea } from '../../../components/ui/textarea';
import type { FormDataState } from '../types/library.types';

interface ContentFormProps {
  formData: FormDataState;
  updateForm: (updates: Partial<FormDataState>) => void;
  errors: { [key: string]: string };
  setErrors: Dispatch<SetStateAction<{ [key: string]: string }>>;
  contentRef: RefObject<HTMLTextAreaElement | null>;
  editorHeight: string;
  onInsertFormatting: (format: string) => void;
  categorySection: ReactNode;
}

export function ContentForm({
  formData,
  updateForm,
  errors,
  setErrors,
  contentRef,
  editorHeight,
  onInsertFormatting,
  categorySection
}: ContentFormProps) {
  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Type className="h-5 w-5 text-green-600" />
            المعلومات الأساسية
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="space-y-2">
            <Label htmlFor="title">
              عنوان المقال <span className="text-red-600 text-xs">(هذا الحقل مطلوب)</span>
            </Label>
            <Input
              id="title"
              placeholder="مثال: البياض الدقيقي في العنب"
              value={formData.title}
              onChange={(e) => {
                updateForm({ title: e.target.value });
                if (errors.title) setErrors(prev => ({ ...prev, title: '' }));
              }}
              onBlur={() => {
                if (!formData.title.trim()) {
                  setErrors(prev => ({ ...prev, title: 'هذا الحقل مطلوب' }));
                }
              }}
              className={`text-right ${errors.title ? 'border-red-500' : ''}`}
            />
            {errors.title && <p className="text-red-600 text-sm">{errors.title}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">
              الوصف المختصر <span className="text-red-600 text-xs">(هذا الحقل مطلوب)</span>
            </Label>
            <Textarea
              id="description"
              placeholder="مقدمة قصيرة عن المرض وأعراضه الأساسية"
              value={formData.shortDescription}
              onChange={(e) => {
                updateForm({ shortDescription: e.target.value });
                if (errors.shortDescription) setErrors(prev => ({ ...prev, shortDescription: '' }));
              }}
              onBlur={() => {
                if (!formData.shortDescription.trim()) {
                  setErrors(prev => ({ ...prev, shortDescription: 'هذا الحقل مطلوب' }));
                }
              }}
              className={`text-right min-h-[100px] ${errors.shortDescription ? 'border-red-500' : ''}`}
            />
            {errors.shortDescription && <p className="text-red-600 text-sm">{errors.shortDescription}</p>}
          </div>

          {categorySection}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>
            محتوى المقال <span className="text-red-600 text-xs">(هذا الحقل مطلوب)</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap gap-2 p-3 bg-gray-50 rounded-lg border">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('mainHeading')}
              title="عنوان رئيسي"
            >
              <span className="text-xs font-bold">H1</span>
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('heading')}
              title="عنوان فرعي"
            >
              <span className="text-xs font-bold">H2</span>
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('bold')}
              title="نص غامق"
            >
              <Bold className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('italic')}
              title="نص مائل"
            >
              <Italic className="h-4 w-4" />
            </Button>
            <Separator orientation="vertical" className="h-8" />
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('list')}
              title="قائمة نقطية"
            >
              <List className="h-4 w-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onInsertFormatting('numberedList')}
              title="قائمة مرقمة"
            >
              <ListOrdered className="h-4 w-4" />
            </Button>
          </div>
          <div className="md:grid md:grid-cols-2 gap-4 items-start md:auto-rows-fr">
            <div className="flex flex-col md:col-span-1 md:min-h-0">
              <Textarea
                ref={contentRef}
                placeholder="اكتب محتوى المقال هنا...

يمكنك استخدام الأزرار أعلاه للتنسيق:
## للعناوين الفرعية
**للنص الغامق**
*للنص المائل*
• للقوائم النقطية
1. للقوائم المرقمة"
                value={formData.content}
                onChange={(e) => {
                  updateForm({ content: e.target.value });
                  if (errors.content) setErrors(prev => ({ ...prev, content: '' }));
                }}
                onBlur={() => {
                  if (!formData.content.trim()) {
                    setErrors(prev => ({ ...prev, content: 'يرجى إدخال محتوى المقال' }));
                  }
                }}
                className={`
                  text-right
                  ${editorHeight}
                  resize-none
                  overflow-auto
                  leading-8
                  text-base
                  ${errors.content ? 'border-red-500' : ''}
                `}
              />
              {errors.content && <p className="text-red-600 text-sm mt-1">{errors.content}</p>}
            </div>

            <div
              className={`
                border border-gray-200
                rounded-lg
                p-4
                bg-white
                ${editorHeight}
                overflow-auto
                md:min-h-0
                will-change-transform
                transition-opacity duration-200
                opacity-100
              `}
            >
              {formData.content.trim() ? (
                <div
                  dir="rtl"
                  className="
                    prose prose-sm max-w-none
                    text-right
                    leading-7
                    break-words
                    overflow-x-hidden
                    [&_pre]:overflow-x-auto
                    [&_code]:break-words
                    [&_p]:my-0
                    [&_ul]:pr-6
                    [&_ol]:pr-6
                  "
                >
                  <ReactMarkdown
                    remarkPlugins={[remarkGfm, remarkBreaks]}
                    rehypePlugins={[rehypeSanitize]}
                  >
                    {formData.content}
                  </ReactMarkdown>
                </div>
              ) : (
                <p className="text-gray-400">معاينة المحتوى هنا...</p>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </>
  );
}
