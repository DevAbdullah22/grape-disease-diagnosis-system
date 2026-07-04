// hook مركزي لإدارة شاشة إضافة وتحرير محتوى المكتبة.
// يقوم بجلب الحالة الأولية، وإدارة حقول النموذج، والتحقق من الصحة، وإدارة صورة الغلاف، والمصادر.
import { useState, useRef, useEffect, useMemo, useCallback } from 'react';
import { toast } from 'sonner';
import { useLibraryCategories } from './useLibraryCategories';
import { useLibraryItemSubmit } from './useLibraryItemSubmit';
import { isValidSecureSourceUrl } from '../utils/urlUtils';
import type { ContentItem, FormDataState } from '../types/library.types';

interface AddContentScreenProps {
    onAddContent?: (content: ContentItem) => void;
    editingContent?: ContentItem | null;
    onUpdateContent?: (content: ContentItem) => void;
}

const EMPTY_INITIAL_EDITOR_DATA = {
    title: '',
    shortDescription: '',
    content: '',
    image: '',
    sources: ['']
};

// يبني البيانات الأولية للمحرر عند وجود عنصر للتحرير.
function buildInitialEditorData(editingContent?: ContentItem | null) {
    if (!editingContent) {
        return EMPTY_INITIAL_EDITOR_DATA;
    }

    return {
        title: editingContent.title,
        shortDescription: editingContent.shortDescription || '',
        content: editingContent.content,
        image: editingContent.image || '',
        sources:
            editingContent.sources && editingContent.sources.length > 0
                ? [...editingContent.sources]
                : ['']
    };
}

// يبني بيانات النموذج الأولية لحقول الإدخال الموجودة في الشاشة.
function buildInitialFormData(editingContent?: ContentItem | null): FormDataState {
    return {
        title: editingContent?.title || '',
        shortDescription: editingContent?.shortDescription || '',
        category: editingContent?.category || '',
        content: editingContent?.content || '',
        newCategory: ''
    };
}

export function useContentEditor(props: AddContentScreenProps) {
    const { onAddContent, editingContent, onUpdateContent } = props;

    // نعرف إن كانت الشاشة في وضع التحرير أو الإضافة الجديدة.
    const isEditMode = !!editingContent;

    // تهيئة البيانات الأولية مباشرةً مرة واحدة عند فتح الشاشة.
    const [initialData] = useState(() => buildInitialEditorData(editingContent));
    const [formData, setFormData] = useState<FormDataState>(() => buildInitialFormData(editingContent));

    // دالة مساعدة للتحديث الجزئي لحقل النموذج.
    const updateForm = (updates: Partial<typeof formData>) => {
        setFormData(prev => ({ ...prev, ...updates }));
    };

    const [errors, setErrors] = useState<{ [key: string]: string }>({});
    const [imagePreview, setImagePreview] = useState<string>(() => initialData.image);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [sources, setSources] = useState<string[]>(() => [...initialData.sources]);
    const [showNewCategory, setShowNewCategory] = useState(false);

    const handleCategoryLoadError = useCallback(() => {
        toast.error('تعذّر تحميل قائمة الفئات، يمكنك إنشاء فئة جديدة أو إعادة المحاولة لاحقًا');
    }, []);

    // hook فرعي لإدارة تحميل الفئات وإنشاء فئة جديدة ورفع الحالة الخاصة بذلك.
    const {
        categoriesState,
        isCreatingCategory,
        createCategory,
        refreshCategories
    } = useLibraryCategories({
        onLoadError: handleCategoryLoadError
    });

    const [newCategoryError, setNewCategoryError] = useState<string>('');
    const [isLeaveDialogOpen, setIsLeaveDialogOpen] = useState(false);

    // قائمة المصادر بعد تنظيف الفراغات وإزالة الخانات الفارغة.
    const normalizedSources = useMemo(
        () => sources.map(source => source.trim()).filter(Boolean),
        [sources]
    );

    // تحقق من صلاحية الروابط باستخدام دالة التحقق الآمن.
    const invalidSources = useMemo(
        () => normalizedSources.filter(source => !isValidSecureSourceUrl(source)),
        [normalizedSources]
    );
    const hasInvalidSources = invalidSources.length > 0;

    // ترجمة اسم الفئة المختار إلى معرف الفئة الموجود في الحالة.
    const selectedCategoryId = useMemo(() => {
        if (!formData.category) {
            return '';
        }

        const matchedCategory = categoriesState.find(category => category.name === formData.category);
        return matchedCategory?.id ?? '';
    }, [categoriesState, formData.category]);

    // تحقق سريع من بنية النموذج الأساسية قبل الحفظ.
    const isFormValid =
        formData.title.trim().length > 0 &&
        formData.shortDescription.trim().length > 0 &&
        (formData.category || formData.newCategory.trim()) &&
        formData.content.trim().length > 0 &&
        (imagePreview || imageFile) &&
        !hasInvalidSources;

    // في حال كان المستخدم ينشئ فئة جديدة، يجب أن يكون هناك id للفئة بعد إنشائها أو إعادة استخدام فئة موجودة.
    const canSave = isFormValid && (!showNewCategory || !!selectedCategoryId);

    // كشف وجود تغييرات غير محفوظة عن طريق مقارنة الحالة الحالية بالبيانات الأولية.
    const hasUnsavedChanges =
        formData.title !== initialData.title ||
        formData.shortDescription !== initialData.shortDescription ||
        formData.content !== initialData.content ||
        imagePreview !== initialData.image ||
        JSON.stringify(sources) !== JSON.stringify(initialData.sources);

    // تحضير قائمة الأخطاء الظاهرة عندما يكون النموذج غير مكتمل.
    const missing = useMemo(() => {
        const list: string[] = [];
        if (!formData.title.trim()) list.push('العنوان مطلوب');
        if (!formData.shortDescription.trim()) list.push('الوصف المختصر مطلوب');
        if (!(formData.category || formData.newCategory.trim())) list.push('يجب اختيار أو إدخال فئة');
        if (!formData.content.trim()) list.push('المحتوى مطلوب');
        if (!(imagePreview || imageFile)) list.push('الصورة مطلوبة');
        if (hasInvalidSources) {
            list.push('يوجد روابط غير آمنة. يُسمح فقط بروابط https://');
        }
        if (showNewCategory && !selectedCategoryId) list.push('يجب إنشاء الفئة الجديدة أو اختيار واحدة');
        return list;
    }, [formData, imagePreview, imageFile, hasInvalidSources, showNewCategory, selectedCategoryId]);

    // hook آخر لإدارة عملية حفظ العنصر (إنشاء أو تحديث).
    const { submitItem, isSaving } = useLibraryItemSubmit({
        categoriesState,
        createCategory,
        refreshCategories,
        selectedCategoryId,
        formData,
        setFormData,
        setShowNewCategory,
        imageFile,
        imagePreview,
        sources,
        setErrors,
        isEditMode,
        editingContent,
        onUpdateContent,
        onAddContent,
        isValidSecureSourceUrl
    });

    // تفعيل إنشاء الفئة الجديدة من الشاشة نفسها.
    const handleCreateCategoryNow = async () => {
        const name = formData.newCategory.trim();
        if (!name) {
            setNewCategoryError('يرجى إدخال اسم الفئة');
            return;
        }
        const normalized = (n: string) => n.trim().toLowerCase();
        if (categoriesState.some(c => normalized(c.name) === normalized(name))) {
            setNewCategoryError('الفئة موجودة بالفعل');
            return;
        }
        setNewCategoryError('');
        try {
            const created = await createCategory({ name });
            updateForm({ category: created.name, newCategory: '' });
            setShowNewCategory(false);
            toast.success(`تم إنشاء الفئة الجديدة: ${created.name}`);
        } catch {
            setNewCategoryError('فشل في إنشاء الفئة الجديدة');
            toast.error('فشل في إنشاء الفئة الجديدة');
        }
    };

    const fileInputRef = useRef<HTMLInputElement>(null);
    const contentRef = useRef<HTMLTextAreaElement>(null);

    // إذا كان هناك تغييرات غير محفوظة، نضيف حدث قبل إغلاق الصفحة ليمنع الخروج بالمحتوى غير المحفوظ.
    useEffect(() => {
        const handler = (e: BeforeUnloadEvent) => {
            if (!hasUnsavedChanges) return;
            e.preventDefault();
            e.returnValue = '';
        };

        window.addEventListener('beforeunload', handler);
        return () => window.removeEventListener('beforeunload', handler);
    }, [hasUnsavedChanges]);

    const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) {
                toast.error('حجم الصورة يجب أن يكون أقل من 5 ميجابايت');
                return;
            }
            if (!file.type.startsWith('image/')) {
                toast.error('يرجى اختيار ملف صورة صحيح');
                return;
            }
            const reader = new FileReader();
            reader.onload = () => {
                setImagePreview(reader.result as string);
                setImageFile(file);
            };
            reader.readAsDataURL(file);
        }
    };

    const removeImage = () => {
        setImagePreview('');
        setImageFile(null);
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    // إضافة حقل مصدر جديد فقط إذا كان الحقل الحالي ممتلئًا.
    const addSource = () => {
        if (sources.length > 0 && !sources[sources.length - 1].trim()) {
            return;
        }
        setSources([...sources, '']);
    };

    const updateSource = (index: number, value: string) => {
        const newSources = [...sources];
        newSources[index] = value;
        setSources(newSources);
        if (errors.sources) {
            setErrors(prev => {
                const next = { ...prev };
                delete next.sources;
                return next;
            });
        }
    };

    const removeSource = (index: number) => {
        if (sources.length > 1) {
            setSources(sources.filter((_, i) => i !== index));
        }
    };

    // إدراج تنسيق Markdown داخل محتوى المقال.
    const insertFormatting = (format: string) => {
        const textarea = contentRef.current;
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const selectedText = formData.content.substring(start, end);
        let insertText = '';
        let cursorShift = 0;

        switch (format) {
            case 'bold':
                insertText = `**${selectedText || 'نص غامق'}**`;
                cursorShift = selectedText ? 0 : -2;
                break;
            case 'italic':
                insertText = `*${selectedText || 'نص مائل'}*`;
                cursorShift = selectedText ? 0 : -1;
                break;
            case 'mainHeading':
                insertText = `
# ${selectedText || 'عنوان رئيسي'}
`;
                cursorShift = selectedText ? 0 : -selectedText.length;
                break;
            case 'heading':
                insertText = `
## ${selectedText || 'عنوان فرعي'}
`;
                cursorShift = selectedText ? 0 : -selectedText.length;
                break;
            case 'list':
                insertText = `
- ${selectedText || 'عنصر'}
`;
                cursorShift = selectedText ? 0 : -selectedText.length;
                break;
            case 'numberedList':
                insertText = `
1. ${selectedText || 'عنصر'}
`;
                cursorShift = selectedText ? 0 : -selectedText.length;
                break;
        }

        const newContent =
            formData.content.slice(0, start) +
            insertText +
            formData.content.slice(end);

        setFormData({ ...formData, content: newContent });

        requestAnimationFrame(() => {
            const pos = start + insertText.length + cursorShift;
            textarea.setSelectionRange(pos, pos);
            textarea.focus();
        });
    };

    // تحقق نهائي من النموذج قبل حفظه وعرض الأخطاء في الواجهة.
    const validateForm = (): boolean => {
        if (canSave) {
            return true;
        }
        const newErrors: { [key: string]: string } = {};
        if (!formData.title.trim()) newErrors.title = 'هذا الحقل مطلوب';
        if (!formData.shortDescription.trim()) newErrors.shortDescription = 'هذا الحقل مطلوب';
        if (!(formData.category || formData.newCategory.trim())) {
            newErrors.category = 'يرجى اختيار أو إدخال فئة المحتوى';
        }
        if (!formData.content.trim()) newErrors.content = 'يرجى إدخال محتوى المقال';
        if (!imagePreview && !imageFile) newErrors.image = 'الصورة مطلوبة';
        const invalidSourceValues = sources
            .map(source => source.trim())
            .filter(source => source && !isValidSecureSourceUrl(source));
        if (invalidSourceValues.length > 0) {
            newErrors.sources = 'يوجد روابط غير صالحة. استخدم https:// فقط وتجنب الروابط غير الآمنة.';
        }
        if (showNewCategory && !selectedCategoryId) {
            newErrors.category = 'يجب إنشاء الفئة الجديدة أو اختيار واحدة';
        }
        setErrors(newErrors);
        return false;
    };

    // حفظ المحتوى مع التحقق من صحة النموذج ثم استدعاء submitItem من hook الحفظ.
    const handleSave = async () => {
        if (!validateForm()) {
            return false;
        }
        return await submitItem();
    };

    // إذا كانت هناك تغييرات غير محفوظة، يفتح حوار التأكيد، وإلا يسمح بالخروج.
    const handleCancel = () => {
        if (hasUnsavedChanges) {
            setIsLeaveDialogOpen(true);
            return false;
        }
        return true;
    };

    return {
        formData,
        errors,
        imagePreview,
        showNewCategory,
        categoriesState,
        isCreatingCategory,
        isSaving,
        canSave,
        missing,
        hasUnsavedChanges,
        isEditMode,
        fileInputRef,
        contentRef,
        isLeaveDialogOpen,
        setIsLeaveDialogOpen,
        newCategoryError,
        sources,
        setSources,
        setErrors,
        setShowNewCategory,
        setNewCategoryError,
        updateForm,
        handleCreateCategoryNow,
        handleImageUpload,
        removeImage,
        addSource,
        updateSource,
        removeSource,
        insertFormatting,
        handleSave,
        handleCancel
    };
}
