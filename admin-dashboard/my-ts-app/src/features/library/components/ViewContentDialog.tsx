// هذا المكون يعرض نافذة حوار لعرض تفاصيل عنصر المحتوى بالكامل.
// يستخدم ReactMarkdown لعرض النص بصيغة Markdown مع تعقيم المحتوى.
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle
} from "../../../components/ui/dialog";
import { Badge } from "../../../components/ui/badge";
import { Button } from "../../../components/ui/button";
import { Calendar } from "lucide-react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeSanitize from "rehype-sanitize";
import { getCategoryColor } from "../utils/categoryUtils";
import type { ContentItem } from "../types/library.types";

interface ViewContentDialogProps {
  content: ContentItem | null;
  onClose: () => void;
}

export function ViewContentDialog({
  content,
  onClose
}: ViewContentDialogProps) {
  // إذا لم يكن هناك محتوى محدد، لا يتم عرض النافذة
  if (!content) {
    return null;
  }

  return (
    <Dialog open={!!content} onOpenChange={onClose}>
      <DialogContent
        className="w-[95vw] md:w-[70vw] lg:w-[40vw] md:max-w-5xl max-h-[95vh] overflow-y-auto bg-white rounded-xl"
        dir="rtl"
        style={{ direction: "rtl" }}
      >
        {/* رأس النافذة */}
        <DialogHeader className="border-b pb-4 text-right items-end">
          <DialogTitle className="text-2xl font-bold text-gray-900">
            عرض المحتوى
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-6 pt-4 text-right" dir="rtl">
          {/* عرض الصورة أو عنصر احتياطي في حال عدم وجود صورة */}
          {content.image ? (
            <img
              src={content.image}
              alt={content.title}
              className="w-full h-80 object-cover rounded-lg shadow-md"
            />
          ) : (
            <div className="w-full h-80 bg-gray-100 flex items-center justify-center text-gray-400 rounded-lg">
              لا توجد صورة
            </div>
          )}

          {/* معلومات العنوان والفئة والتاريخ */}
          <div className="space-y-4 text-right" dir="rtl">
            <h2 className="text-3xl font-bold text-gray-900">
              {content.title}
            </h2>
            <div
              className="flex w-full items-center justify-between gap-3"
              dir="rtl"
            >
              <Badge
                className={`${getCategoryColor(content.category)} px-4 py-2 text-base border`}
              >
                {content.category}
              </Badge>
              <div
                className="inline-flex items-center gap-2 text-base text-gray-500"
                dir="ltr"
              >
                <Calendar className="h-5 w-5 shrink-0" />
                <span className="tracking-wide">{content.createdAt}</span>
              </div>
            </div>
          </div>

          {/* الوصف المختصر إذا كان متاحًا */}
          {content.shortDescription && (
            <div className="text-lg text-gray-700 bg-gray-50 p-4 rounded-lg">
              {content.shortDescription}
            </div>
          )}

          {/* محتوى Markdown الممرر من العنصر */}
          <div
            className="prose max-w-none text-gray-800  text-lg leading-relaxed bg-gray-50 p-6 rounded-lg text-right [&_*]:text-right [&_ul]:pr-6 [&_ol]:pr-6"
            dir="rtl"
          >
            <ReactMarkdown
              remarkPlugins={[remarkGfm]}
              rehypePlugins={[rehypeSanitize]}
            >
              {content.content}
            </ReactMarkdown>
          </div>

          {/* قائمة المصادر إن وجدت */}
          {content.sources && content.sources.length > 0 && (
            <div className="bg-blue-50 p-4 rounded-lg">
              <h3 className="font-semibold text-xl mb-3">المصادر</h3>
              <ul className="list-disc pr-6 space-y-2 text-right" dir="rtl">
                {content.sources.map((s, i) => (
                  <li key={i}>
                    <a
                      href={s}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 underline hover:text-blue-800 text-base break-all"
                      dir="ltr"
                    >
                      {s}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* زر إغلاق النافذة */}
          <div className="flex justify-end gap-4 pt-6 border-t">
            <Button
              onClick={onClose}
              variant="outline"
              className="px-6 py-3 text-lg"
            >
              إغلاق
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
